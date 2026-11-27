import 'package:get_it/get_it.dart';
import '../data/favorites_data_source.dart';
import '../../features/home/data/repositories/mock_catalog_repository.dart';
import '../../features/home/data/repositories/remote_catalog_repository.dart';
import '../../features/home/domain/repositories/catalog_repository.dart';
import '../../features/home/domain/usecases/get_catalog_books.dart';
import '../../features/home/domain/usecases/get_categories.dart';
import '../../features/home/domain/usecases/get_featured_books.dart';
import '../../features/home/domain/usecases/watch_favorite_ids.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/book_details/data/repositories/mock_book_repository.dart';
import '../../features/book_details/data/repositories/remote_book_repository.dart';
import '../../features/book_details/domain/repositories/book_repository.dart';
import '../../features/book_details/domain/usecases/get_book_details.dart';
import '../../features/book_details/domain/usecases/toggle_favorite.dart';
import '../../features/book_details/domain/usecases/add_to_cart.dart';
import '../../features/book_details/presentation/bloc/book_details_bloc.dart';
import '../../features/favorites/domain/repositories/favorites_repository.dart';
import '../../features/favorites/domain/usecases/get_favorites.dart';
import '../../features/favorites/domain/usecases/watch_favorites.dart';
import '../../features/favorites/domain/usecases/remove_favorite.dart';
import '../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/library/domain/repositories/rentals_repository.dart';
import '../../features/library/domain/repositories/uploads_repository.dart';
import '../../features/library/domain/usecases/get_active_rentals.dart';
import '../../features/library/domain/usecases/get_my_uploads.dart';
import '../../features/library/domain/usecases/delete_upload.dart';
import '../../features/library/presentation/bloc/library_bloc.dart';
import '../../features/activity/data/repositories/remote_activity_repository.dart';
import '../../features/activity/domain/repositories/activity_repository.dart';
import '../../features/activity/domain/usecases/get_activity_feed.dart';
import '../../features/activity/domain/usecases/act_on_request.dart';
import '../../features/activity/presentation/bloc/activity_bloc.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile_summary.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/account_settings/domain/repositories/settings_repository.dart';
import '../../features/account_settings/domain/usecases/get_settings.dart';
import '../../features/account_settings/domain/usecases/update_settings.dart';
import '../../features/account_settings/domain/usecases/change_password.dart';
import '../../features/account_settings/domain/usecases/upload_avatar.dart';
import '../../features/account_settings/presentation/bloc/settings_bloc.dart';
import '../../features/order_history/domain/repositories/orders_repository.dart';
import '../../features/order_history/domain/usecases/get_orders.dart';
import '../../features/order_history/domain/usecases/get_order_stats.dart';
import '../../features/order_history/presentation/bloc/orders_bloc.dart';
import '../../features/buy_now/presentation/bloc/buy_now_bloc.dart';
import '../../features/cart/data/datasources/cart_data_source.dart';
import '../../features/cart/data/repositories/mock_cart_repository.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/domain/usecases/watch_cart.dart';
import '../../features/cart/domain/usecases/get_cart.dart';
import '../../features/cart/domain/usecases/remove_cart_item.dart';
import '../../features/cart/domain/usecases/update_cart_item_quantity.dart';
import '../../features/cart/domain/usecases/set_cart_delivery_address.dart';
import '../../features/cart/domain/usecases/cart_checkout.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/delivery_address/domain/repositories/address_repository.dart';
import '../../features/delivery_address/domain/usecases/get_saved_addresses.dart';
import '../../features/delivery_address/domain/usecases/add_new_address.dart';
import '../../features/delivery_address/domain/usecases/edit_address.dart';
import '../../features/delivery_address/domain/usecases/select_address.dart';
import '../../features/delivery_address/domain/usecases/delete_address.dart';
import '../../features/delivery_address/presentation/bloc/address_bloc.dart';
import '../../features/support/domain/repositories/support_repository.dart';
import '../../features/support/domain/usecases/get_faqs.dart';
import '../../features/support/domain/usecases/search_faqs.dart';
import '../../features/support/presentation/bloc/support_bloc.dart';
import '../../features/report_issue/domain/repositories/issue_repository.dart';
import '../../features/report_issue/domain/usecases/submit_report.dart';
import '../../features/report_issue/presentation/bloc/report_issue_bloc.dart';
import '../../features/feedback/domain/repositories/feedback_repository.dart';
import '../../features/feedback/domain/usecases/submit_feedback.dart';
import '../../features/feedback/presentation/bloc/feedback_bloc.dart';
import '../../features/terms/domain/repositories/terms_repository.dart';
import '../../features/terms/domain/usecases/get_terms.dart';
import '../../features/terms/domain/usecases/acknowledge_terms.dart';
import '../../features/terms/presentation/bloc/terms_bloc.dart';
import '../../features/book_owner_details/domain/repositories/listing_repository.dart';
import '../../features/book_owner_details/data/repositories/listing_repository_impl.dart';
import '../../features/book_owner_details/domain/usecases/get_listing_details.dart';
import '../../features/book_owner_details/domain/usecases/edit_listing.dart';
import '../../features/book_owner_details/domain/usecases/delete_listing.dart';
import '../../features/book_owner_details/presentation/bloc/book_owner_details_bloc.dart';
import '../../features/add_book/domain/repositories/add_book_repository.dart';
import '../../features/add_book/data/repositories/mock_add_book_repository.dart';
import '../../features/add_book/domain/repositories/listing_repository.dart'
    as add_book_listing;
import '../../features/add_book/data/repositories/listing_repository_impl.dart'
    as add_book_listing_impl;
import '../../features/add_book/domain/usecases/lookup_isbn.dart';
import '../../features/add_book/domain/usecases/create_draft.dart';
import '../../features/add_book/domain/usecases/update_category.dart';
import '../../features/add_book/presentation/bloc/add_book_bloc.dart';
import '../../features/add_book/presentation/bloc/add_book_step_2_bloc.dart';
import '../../features/add_book_review/domain/repositories/draft_listing_repository.dart';
import '../../features/add_book_review/data/repositories/remote_draft_listing_repository.dart';
import '../../features/add_book_review/domain/usecases/get_draft_review.dart';
import '../../features/add_book_review/domain/usecases/publish_draft.dart';
import '../../features/add_book_review/domain/usecases/save_draft.dart';
import '../../features/add_book_review/presentation/bloc/add_book_review_bloc.dart';
import '../../features/provider_portfolio/presentation/bloc/provider_portfolio_bloc.dart';

import '../../features/favorites/data/repositories/mock_favorites_repository.dart';
import '../../features/favorites/data/repositories/remote_favorites_repository.dart';
import '../../features/profile/data/repositories/mock_profile_repository.dart';
import '../../features/profile/data/repositories/remote_profile_repository.dart';
import '../../features/account_settings/data/repositories/remote_settings_repository.dart';
import '../../features/order_history/data/repositories/mock_orders_repository.dart';
import '../../features/order_history/data/repositories/remote_orders_repository.dart';
import '../../features/cart/data/repositories/remote_cart_repository.dart';
import '../../features/delivery_address/data/repositories/mock_address_repository.dart';
import '../../features/delivery_address/data/repositories/remote_address_repository.dart';
import '../../features/support/data/repositories/mock_support_repository.dart';
import '../../features/support/data/repositories/remote_support_repository.dart';
import '../../features/report_issue/data/repositories/remote_issue_repository.dart';
import '../../features/feedback/data/repositories/remote_feedback_repository.dart';
import '../../features/terms/data/repositories/static_terms_repository.dart';
import '../../features/library/data/repositories/mock_library_repository.dart';
import '../../features/library/data/repositories/remote_library_repository.dart';

import '../../core/network/api_client.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';

const bool useMock = false;

final sl = GetIt.instance;

Future<void> initServiceLocator(AppEnvironment env) async {
  // Update static ApiService.baseUrl with the current environment's API URL
  ApiService.baseUrl = env.apiUrl;

  // Register environment configuration singleton
  sl.registerSingleton<AppEnvironment>(env);

  // --- External Dependencies ---
  sl.registerLazySingleton(() => ApiClient(baseUrl: env.apiUrl));

  // --- Core ---
  sl.registerLazySingleton<FavoritesDataSource>(() => FavoritesDataSource());
  // sl.registerLazySingleton<AppRouter>(() => AppRouter());

  // --- Features ---

  // Home Feature
  sl.registerLazySingleton<CatalogRepository>(
    () => useMock ? MockCatalogRepository(sl()) : RemoteCatalogRepository(sl()),
  );

  // Book Details Feature
  sl.registerLazySingleton<BookRepository>(
    () => useMock
        ? MockBookRepository(sl(), sl())
        : RemoteBookRepository(sl(), sl()),
  );

  // Buy Now Feature
  sl.registerFactory(() => BuyNowBloc(apiClient: sl()));

  // Favorites Feature
  sl.registerLazySingleton<FavoritesRepository>(
    () => useMock
        ? MockFavoritesRepository(sl())
        : RemoteFavoritesRepository(sl(), sl()),
  );

  // Library Feature
  sl.registerLazySingleton<RentalsRepository>(
    () => useMock ? MockLibraryRepository() : RemoteLibraryRepository(sl()),
  );
  sl.registerLazySingleton<UploadsRepository>(
    () => useMock ? MockLibraryRepository() : RemoteLibraryRepository(sl()),
  );

  // Activity Feature
  sl.registerLazySingleton<ActivityRepository>(
    () => RemoteActivityRepository(sl()),
  );

  // Profile Feature
  sl.registerLazySingleton<ProfileRepository>(
    () => useMock ? MockProfileRepository() : RemoteProfileRepository(sl()),
  );

  // Account Settings Feature
  sl.registerLazySingleton<SettingsRepository>(
    () => RemoteSettingsRepository(sl()),
  );

  // Order History Feature
  sl.registerLazySingleton<OrdersRepository>(
    () => useMock ? MockOrdersRepository() : RemoteOrdersRepository(sl()),
  );

  // Cart Feature
  sl.registerLazySingleton<CartDataSource>(() => CartDataSource());
  sl.registerLazySingleton<CartRepository>(
    () => useMock ? MockCartRepository(sl()) : RemoteCartRepository(sl(), sl()),
  );

  // Delivery Address Feature
  sl.registerLazySingleton<AddressRepository>(
    () => useMock ? MockAddressRepository() : RemoteAddressRepository(sl()),
  );

  // Support Feature
  sl.registerLazySingleton<SupportRepository>(
    () => useMock ? MockSupportRepository() : RemoteSupportRepository(sl()),
  );

  // Report Issue Feature
  sl.registerLazySingleton<IssueRepository>(() => RemoteIssueRepository(sl()));

  // Feedback Feature
  sl.registerLazySingleton<FeedbackRepository>(
    () => RemoteFeedbackRepository(sl()),
  );

  // Terms & Conditions Feature
  sl.registerLazySingleton<TermsRepository>(() => StaticTermsRepository());

  // Book Owner Details Feature
  sl.registerLazySingleton<ListingRepository>(
    () => ListingRepositoryImpl(bookRepository: sl()),
  );

  sl.registerLazySingleton<AddBookRepository>(() => MockAddBookRepository());

  // Add Book Review Feature
  sl.registerLazySingleton<DraftListingRepository>(
    () => RemoteDraftListingRepository(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetFeaturedBooks(sl()));
  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => GetCatalogBooks(sl()));
  sl.registerLazySingleton(() => WatchFavoriteIds(sl()));

  sl.registerLazySingleton(() => GetBookDetails(sl()));
  sl.registerLazySingleton(() => ToggleFavorite(sl()));
  sl.registerLazySingleton(() => AddToCart(sl()));

  sl.registerLazySingleton(() => GetFavorites(sl()));
  sl.registerLazySingleton(() => WatchFavorites(sl()));
  sl.registerLazySingleton(() => RemoveFavorite(sl()));

  sl.registerLazySingleton(() => GetActiveRentals(sl()));
  sl.registerLazySingleton(() => GetMyUploads(sl()));
  sl.registerLazySingleton(() => DeleteUpload(sl()));

  sl.registerLazySingleton(() => GetProfileSummary(sl()));

  sl.registerLazySingleton(() => GetSettings(sl()));
  sl.registerLazySingleton(() => UpdateSettings(sl()));
  sl.registerLazySingleton(() => ChangePassword(sl()));
  sl.registerLazySingleton(() => UploadAvatar(sl()));

  sl.registerLazySingleton(() => GetSavedAddresses(sl()));
  sl.registerLazySingleton(() => AddNewAddress(sl()));
  sl.registerLazySingleton(() => EditAddress(sl()));
  sl.registerLazySingleton(() => SelectAddress(sl()));
  sl.registerLazySingleton(() => DeleteAddress(sl()));

  sl.registerLazySingleton(() => GetOrders(sl()));
  sl.registerLazySingleton(() => GetOrderStats(sl()));

  sl.registerLazySingleton(() => WatchCart(sl()));
  sl.registerLazySingleton(() => GetCart(sl()));
  sl.registerLazySingleton(() => RemoveCartItem(sl()));
  sl.registerLazySingleton(() => UpdateCartItemQuantity(sl()));
  sl.registerLazySingleton(() => SetCartDeliveryAddress(sl()));
  sl.registerLazySingleton(() => CartCheckout(sl()));

  sl.registerLazySingleton(() => GetFaqs(sl()));
  sl.registerLazySingleton(() => SearchFaqs(sl()));

  sl.registerLazySingleton(() => SubmitReport(sl()));

  sl.registerLazySingleton(() => SubmitFeedback(sl()));

  sl.registerLazySingleton(() => GetTerms(sl()));
  sl.registerLazySingleton(() => AcknowledgeTerms(sl()));

  sl.registerLazySingleton(() => GetListingDetails(sl()));
  sl.registerLazySingleton(() => EditListing(sl()));
  sl.registerLazySingleton(() => DeleteListing(sl()));

  sl.registerLazySingleton(() => GetActivityFeed(sl()));
  sl.registerLazySingleton(() => ActOnRequest(sl()));

  sl.registerLazySingleton(() => LookupIsbn(sl()));
  sl.registerLazySingleton(() => CreateDraft(sl()));
  sl.registerLazySingleton(() => UpdateCategory(sl()));

  sl.registerLazySingleton(() => GetDraftReview(sl()));
  sl.registerLazySingleton(() => PublishDraft(sl()));
  sl.registerLazySingleton(() => SaveDraft(sl()));

  // Blocs
  sl.registerFactory(
    () => HomeBloc(
      getFeaturedBooks: sl(),
      getCategories: sl(),
      getCatalogBooks: sl(),
      toggleFavorite: sl(),
      watchFavoriteIds: sl(),
    ),
  );

  sl.registerFactory(
    () => BookDetailsBloc(
      getBookDetails: sl(),
      toggleFavorite: sl(),
      addToCart: sl(),
      bookRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => FavoritesBloc(
      getFavorites: sl(),
      watchFavorites: sl(),
      removeFavorite: sl(),
    ),
  );

  sl.registerFactory(
    () => LibraryBloc(
      getActiveRentals: sl(),
      getMyUploads: sl(),
      deleteUpload: sl(),
    ),
  );

  sl.registerFactory(
    () => ActivityBloc(getActivityFeed: sl(), actOnRequest: sl()),
  );

  sl.registerFactory(() => ProfileBloc(getProfileSummary: sl()));

  sl.registerFactory(
    () => SettingsBloc(
      getSettings: sl(), 
      updateSettings: sl(),
      changePassword: sl(),
      uploadAvatar: sl(),
    ),
  );

  sl.registerFactory(() => OrdersBloc(getOrders: sl(), getOrderStats: sl()));

  sl.registerFactory(
    () => CartBloc(
      watchCart: sl(),
      getCart: sl(),
      removeCartItem: sl(),
      updateCartItemQuantity: sl(),
      cartCheckout: sl(),
    ),
  );

  sl.registerFactory(
    () => AddressBloc(
      getSavedAddresses: sl(),
      addNewAddress: sl(),
      editAddress: sl(),
      selectAddress: sl(),
      deleteAddress: sl(),
      setCartDeliveryAddress: sl(),
    ),
  );

  sl.registerFactory(() => SupportBloc(getFaqs: sl(), searchFaqs: sl()));

  sl.registerFactory(() => ReportIssueBloc(submitReport: sl()));

  sl.registerFactory(() => FeedbackBloc(submitFeedback: sl()));

  sl.registerFactory(() => TermsBloc(getTerms: sl(), acknowledgeTerms: sl()));

  sl.registerFactory(
    () => BookOwnerDetailsBloc(
      getListingDetails: sl(),
      editListing: sl(),
      deleteListing: sl(),
    ),
  );

  sl.registerLazySingleton(
    () =>
        AddBookBloc(lookupIsbn: sl(), createDraft: sl(), updateCategory: sl()),
  );

  sl.registerLazySingleton<add_book_listing.ListingRepository>(
    () => add_book_listing_impl.ListingRepositoryImpl(apiClient: sl()),
  );

  sl.registerFactory(() => AddBookStep2Bloc(listingRepository: sl()));

  sl.registerFactory(
    () => AddBookReviewBloc(
      getDraftReview: sl(),
      publishDraft: sl(),
      saveDraft: sl(),
    ),
  );

  sl.registerFactory(() => ProviderPortfolioBloc());
}
