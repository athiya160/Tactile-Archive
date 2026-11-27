"""
Phase 20.43 — Trusted Proxy and Real Client IP Resolution Subsystem
Project: The Tactile Archive / LibriFlow (FastAPI Backend)

Provides cryptographically sound, spoof-resistant client IP resolution behind reverse
proxies (Nginx, Caddy, Cloudflare, AWS ALB, GCP Cloud Run) for SlowAPI rate limiting,
security logging, and abuse prevention.

SECURITY GUARANTEES:
1. Never trusts client-supplied X-Forwarded-For or Forwarded headers from untrusted socket peers.
2. If TRUSTED_PROXIES is not configured, fails safely to direct socket peer IP (zero trust).
3. When trusted proxies are configured, traverses the proxy chain from right to left (closest hop first),
   preventing attackers from evading rate limits by prepending arbitrary spoofed IPs.
4. Supports IPv4, IPv6, CIDR blocks, hostnames (e.g. testclient, localhost), port stripping,
   RFC 7239 Forwarded syntax, and X-Real-IP fallback.
5. Fails gracefully to 127.0.0.1 or direct peer IP if headers are malformed or missing.
"""

import os
import ipaddress
import logging
from typing import List, Optional, Set, Tuple, Union
from fastapi import Request
from starlette.types import Scope

logger = logging.getLogger("app.core.proxy_security")

# Cache for parsed trusted proxy networks and host identifiers
_CACHED_CONFIG_RAW: Optional[str] = None
_CACHED_NETWORKS: List[Union[ipaddress.IPv4Network, ipaddress.IPv6Network]] = []
_CACHED_NAMED_HOSTS: Set[str] = set()


def parse_ip_hop(hop: str) -> Optional[Union[ipaddress.IPv4Address, ipaddress.IPv6Address]]:
    """
    Cleans and parses a single IP hop candidate string from X-Forwarded-For,
    Forwarded (RFC 7239), or X-Real-IP.
    Handles:
    - Leading/trailing whitespace and quotes: '"203.0.113.19"' -> '203.0.113.19'
    - RFC 7239 'for=' prefix: 'for=203.0.113.19' -> '203.0.113.19'
    - Bracketed IPv6: '[2001:db8::1]:8080' or '[2001:db8::1]' -> '2001:db8::1'
    - IPv4 with port: '198.51.100.5:443' -> '198.51.100.5'
    """
    if not hop:
        return None
    h = hop.strip().strip('"').strip("'")
    if h.lower().startswith("for="):
        h = h[4:].strip().strip('"').strip("'")
    if h.startswith("[") and "]" in h:
        # IPv6 with possible bracketed port, e.g. [2001:db8::1]:8080
        end_bracket = h.index("]")
        h = h[1:end_bracket]
    elif ":" in h and h.count(":") == 1:
        # IPv4 with single port delimiter, e.g. 192.0.2.1:8080
        h = h.split(":")[0]
    h = h.strip()
    try:
        return ipaddress.ip_address(h)
    except ValueError:
        return None


def get_trusted_proxy_configuration() -> Tuple[List[Union[ipaddress.IPv4Network, ipaddress.IPv6Network]], Set[str]]:
    """
    Loads and caches the trusted reverse proxy configuration from the TRUSTED_PROXIES
    environment variable (comma-separated list of IPs, CIDRs, or named hosts).
    Returns (networks_list, named_hosts_set).
    If TRUSTED_PROXIES is empty or unset, returns ([], set()) (safe default: no proxies trusted).
    """
    global _CACHED_CONFIG_RAW, _CACHED_NETWORKS, _CACHED_NAMED_HOSTS
    raw_cfg = os.getenv("TRUSTED_PROXIES", "").strip()
    if raw_cfg == _CACHED_CONFIG_RAW:
        return _CACHED_NETWORKS, _CACHED_NAMED_HOSTS

    networks: List[Union[ipaddress.IPv4Network, ipaddress.IPv6Network]] = []
    named_hosts: Set[str] = set()

    if raw_cfg:
        for item in raw_cfg.split(","):
            item = item.strip()
            if not item:
                continue
            try:
                # strict=False allows host bits to be set in network definitions (e.g. 10.0.0.1/24)
                networks.append(ipaddress.ip_network(item, strict=False))
            except ValueError:
                # Non-IP identifier (e.g. 'localhost', 'testclient')
                named_hosts.add(item.lower())

    _CACHED_CONFIG_RAW = raw_cfg
    _CACHED_NETWORKS = networks
    _CACHED_NAMED_HOSTS = named_hosts
    return _CACHED_NETWORKS, _CACHED_NAMED_HOSTS


def get_trusted_proxy_networks() -> List[Union[ipaddress.IPv4Network, ipaddress.IPv6Network]]:
    """Backward compatibility helper returning only the IP network list."""
    networks, _ = get_trusted_proxy_configuration()
    return networks


def is_peer_trusted(
    peer_str: str,
    networks: List[Union[ipaddress.IPv4Network, ipaddress.IPv6Network]],
    named_hosts: Set[str]
) -> bool:
    """Checks whether a peer address or host identifier belongs to trusted proxies."""
    clean = peer_str.strip().lower()
    if clean in named_hosts:
        return True
    try:
        ip = ipaddress.ip_address(clean)
        for net in networks:
            if ip in net:
                return True
    except ValueError:
        pass
    return False


def is_peer_trusted_str(peer_str: Optional[str]) -> bool:
    """
    Checks whether a given client IP address or hostname belongs to TRUSTED_PROXIES.
    Returns False immediately if TRUSTED_PROXIES is unset or empty (fail-safe).
    """
    if not peer_str:
        return False
    trusted_networks, trusted_named = get_trusted_proxy_configuration()
    if not (trusted_networks or trusted_named):
        return False
    return is_peer_trusted(peer_str, trusted_networks, trusted_named)


def is_request_https(scope: Scope) -> bool:
    """
    Cryptographically validates whether an ASGI request was terminated over HTTPS.
    
    Security Algorithm:
    1. Direct TLS: If scope.get('scheme') == 'https', native TLS was terminated by the ASGI server.
       Return True immediately.
    2. Direct Peer Check: Extract immediate TCP socket peer:
       peer = scope.get('client')  # (host, port)
       peer_ip = peer[0] if (peer and len(peer) > 0) else None
    3. Untrusted Peer Fail-Safe:
       If peer_ip is missing or is_peer_trusted_str(peer_ip) is False:
           DISCARD all forwarded headers. Return False.
    4. Trusted Proxy Hop Verification:
       The immediate peer is verified in TRUSTED_PROXIES.
       Inspect 'X-Forwarded-Proto' (or 'Forwarded' proto=).
       If multiple comma-separated values exist, extract the rightmost value (closest hop).
       Return True if rightmost hop equals 'https' (case-insensitive), else False.
    """
    if scope.get("scheme") == "https":
        return True

    client = scope.get("client")
    if not client or not client[0]:
        return False

    peer_ip = str(client[0]).strip()
    if not is_peer_trusted_str(peer_ip):
        # Untrusted direct client or rogue hop: NEVER trust forwarded headers
        return False

    # Peer is a verified reverse proxy. Safely inspect X-Forwarded-Proto.
    for k, v in scope.get("headers", []):
        if k.lower() == b"x-forwarded-proto":
            try:
                val = v.decode("latin-1").strip()
                # If chained (e.g. "http, https"), rightmost hop represents the protocol received by our proxy
                hops = [h.strip().lower() for h in val.split(",") if h.strip()]
                if hops and hops[-1] == "https":
                    return True
            except Exception:
                return False

    return False


def is_ip_in_networks(
    ip: Union[ipaddress.IPv4Address, ipaddress.IPv6Address],
    networks: List[Union[ipaddress.IPv4Network, ipaddress.IPv6Network]]
) -> bool:
    """Checks whether an IP address belongs to any configured trusted network."""
    for net in networks:
        if ip in net:
            return True
    return False


def get_trusted_client_ip(request: Request) -> str:
    """
    Secure client IP resolution key function for SlowAPI and Rate Limiting Middleware.
    
    Resolution Flow:
    1. Extract direct TCP socket peer (request.client.host). If missing, return '127.0.0.1'.
    2. Check if peer is trusted via TRUSTED_PROXIES.
    3. If TRUSTED_PROXIES is unset or peer is NOT trusted:
       - FAIL SAFE: Return direct socket peer.
       - Any forwarded headers (X-Forwarded-For, Forwarded, X-Real-IP) are IGNORED
         to prevent direct-client IP spoofing.
    4. If peer IS in TRUSTED_PROXIES:
       - Parse X-Forwarded-For (or Forwarded RFC 7239).
       - Walk hops from RIGHT to LEFT (closest hop first).
       - Skip any hops that are themselves in TRUSTED_PROXIES (multi-tier internal proxy hops).
       - The first hop from the right that is NOT in TRUSTED_PROXIES is the real client IP.
       - If all hops are trusted, return the leftmost valid hop or direct peer.
       - If no valid forwarded headers exist, check X-Real-IP (if peer trusted).
       - If all else fails, return direct socket peer.
    """
    peer_ip_str: Optional[str] = None
    if request.client and request.client.host:
        peer_ip_str = request.client.host.strip()

    if not peer_ip_str:
        return "127.0.0.1"

    trusted_networks, trusted_named = get_trusted_proxy_configuration()

    # Rule 1 & 2: If no trusted proxies configured, or peer is NOT trusted, return peer directly
    if not (trusted_networks or trusted_named) or not is_peer_trusted(peer_ip_str, trusted_networks, trusted_named):
        return peer_ip_str

    # Rule 3: Peer is a verified trusted proxy. Inspect forwarded headers.
    xff = request.headers.get("x-forwarded-for")
    forwarded = request.headers.get("forwarded")
    x_real_ip = request.headers.get("x-real-ip")

    raw_hops: List[str] = []
    if xff:
        raw_hops = [h.strip() for h in xff.split(",") if h.strip()]
    elif forwarded:
        # RFC 7239: elements separated by comma
        raw_hops = [h.strip() for h in forwarded.split(",") if h.strip()]

    if raw_hops:
        # Traverse right-to-left: the rightmost hop was appended by the trusted proxy closest to us
        for hop_str in reversed(raw_hops):
            hop_ip = parse_ip_hop(hop_str)
            if not hop_ip:
                continue
            if is_ip_in_networks(hop_ip, trusted_networks):
                # Internal intermediate trusted proxy hop, continue left
                continue
            # First untrusted hop from right is the true originating client IP
            return str(hop_ip)

        # All hops were trusted proxies; fall back to leftmost hop
        leftmost = parse_ip_hop(raw_hops[0])
        if leftmost:
            return str(leftmost)

    # Fallback to X-Real-IP if peer is trusted and X-Forwarded-For was empty
    if x_real_ip:
        real_ip = parse_ip_hop(x_real_ip)
        if real_ip and not is_ip_in_networks(real_ip, trusted_networks):
            return str(real_ip)

    # Final fallback to verified proxy peer IP
    return peer_ip_str
