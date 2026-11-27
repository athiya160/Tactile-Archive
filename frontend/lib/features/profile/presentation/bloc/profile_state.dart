import '../../domain/entities/profile_summary.dart';

abstract class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileSummary profile;

  const ProfileLoaded(this.profile);
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);
}
