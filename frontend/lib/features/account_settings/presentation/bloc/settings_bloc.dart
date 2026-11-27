import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_settings.dart';
import '../../domain/usecases/change_password.dart';
import '../../domain/usecases/upload_avatar.dart';

// --- Events ---
abstract class SettingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SettingsStarted extends SettingsEvent {}

class SettingsFieldChanged extends SettingsEvent {
  final String? fullName;
  final String? email;
  final String? phone;
  final String? address;
  final String? bio;

  SettingsFieldChanged({
    this.fullName,
    this.email,
    this.phone,
    this.address,
    this.bio,
  });

  @override
  List<Object?> get props => [fullName, email, phone, address, bio];
}

class SettingsToggleChanged extends SettingsEvent {
  final String key;
  final bool value;

  SettingsToggleChanged(this.key, this.value);

  @override
  List<Object?> get props => [key, value];
}

class SettingsSavePressed extends SettingsEvent {}

class SettingsDiscardPressed extends SettingsEvent {}

class AvatarUploadPressed extends SettingsEvent {
  final ImageSource source;

  AvatarUploadPressed(this.source);

  @override
  List<Object?> get props => [source];
}

class SettingsChangePasswordPressed extends SettingsEvent {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  SettingsChangePasswordPressed({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword, confirmPassword];
}

// --- State ---
enum SettingsStatus { initial, loading, loaded, success, failure }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final SettingsEntity? initialSettings;
  final SettingsEntity? currentSettings;
  final String? selectedAvatarPath;
  final String? errorMessage;
  final String? successMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.initialSettings,
    this.currentSettings,
    this.selectedAvatarPath,
    this.errorMessage,
    this.successMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    SettingsEntity? initialSettings,
    SettingsEntity? currentSettings,
    String? selectedAvatarPath,
    String? errorMessage,
    String? successMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      initialSettings: initialSettings ?? this.initialSettings,
      currentSettings: currentSettings ?? this.currentSettings,
      selectedAvatarPath: selectedAvatarPath ?? this.selectedAvatarPath,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    initialSettings,
    currentSettings,
    selectedAvatarPath,
    errorMessage,
    successMessage,
  ];
}

// --- Bloc ---
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final UpdateSettings updateSettings;
  final ChangePassword? changePassword;
  final UploadAvatar? uploadAvatar;

  SettingsBloc({
    required this.getSettings,
    required this.updateSettings,
    this.changePassword,
    this.uploadAvatar,
  }) : super(const SettingsState()) {
    on<SettingsStarted>(_onStarted);
    on<SettingsFieldChanged>(_onFieldChanged);
    on<SettingsToggleChanged>(_onToggleChanged);
    on<SettingsSavePressed>(_onSavePressed);
    on<SettingsDiscardPressed>(_onDiscardPressed);
    on<AvatarUploadPressed>(_onAvatarUploadPressed);
    on<SettingsChangePasswordPressed>(_onChangePasswordPressed);
  }

  static final defaultSettings = SettingsEntity(
    fullName: 'Athiya Tabassum',
    email: 'athiya160@gmail.com',
    phone: '+91 99864 74220',
    address: 'Bangalore, Karnataka, India',
    bio: 'Bibliophile, avid reader and community member.',
    avatarUrl: '',
    notifications: const {
      'Rent Request': true,
      'Purchase Request': true,
      'New Book Arrival': false,
      'Book Due Reminders': true,
    },
  );

  Future<void> _onStarted(
    SettingsStarted event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await getSettings(NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SettingsStatus.loaded,
          initialSettings: defaultSettings,
          currentSettings: defaultSettings,
        ),
      ),
      (settings) => emit(
        state.copyWith(
          status: SettingsStatus.loaded,
          initialSettings: settings,
          currentSettings: settings,
        ),
      ),
    );
  }

  void _onFieldChanged(
    SettingsFieldChanged event,
    Emitter<SettingsState> emit,
  ) {
    if (state.currentSettings == null) return;

    final updated = state.currentSettings!.copyWith(
      fullName: event.fullName,
      email: event.email,
      phone: event.phone,
      address: event.address,
      bio: event.bio,
    );
    emit(state.copyWith(currentSettings: updated));
  }

  void _onToggleChanged(
    SettingsToggleChanged event,
    Emitter<SettingsState> emit,
  ) {
    if (state.currentSettings == null) return;

    final updatedNotifications = Map<String, bool>.from(
      state.currentSettings!.notifications,
    );
    updatedNotifications[event.key] = event.value;

    final updated = state.currentSettings!.copyWith(
      notifications: updatedNotifications,
    );
    emit(state.copyWith(currentSettings: updated));
  }

  Future<void> _onSavePressed(
    SettingsSavePressed event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.currentSettings == null) return;

    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await updateSettings(state.currentSettings!);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: 'Failed to save settings',
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: SettingsStatus.success,
          initialSettings: state.currentSettings,
          successMessage: 'Settings updated successfully',
        ),
      ),
    );
  }

  void _onDiscardPressed(
    SettingsDiscardPressed event,
    Emitter<SettingsState> emit,
  ) {
    if (state.initialSettings == null) return;
    emit(
      state.copyWith(
        currentSettings: state.initialSettings,
        status: SettingsStatus.loaded,
      ),
    );
  }

  Future<void> _onAvatarUploadPressed(
    AvatarUploadPressed event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.currentSettings == null) return;
    if (uploadAvatar == null) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: 'Avatar upload not supported',
        ),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: event.source);

      if (image != null) {
        emit(state.copyWith(status: SettingsStatus.loading));
        
        final result = await uploadAvatar!(UploadAvatarParams(image.path));
        
        result.fold(
          (failure) => emit(
            state.copyWith(
              status: SettingsStatus.failure,
              errorMessage: 'Failed to upload image: ${failure.message}',
            ),
          ),
          (url) {
            final updated = state.currentSettings!.copyWith(avatarUrl: url);
            // Auto-save the new avatar url to settings
            emit(state.copyWith(
              currentSettings: updated,
              selectedAvatarPath: image.path, // We can keep this for local caching or remove
            ));
            add(SettingsSavePressed());
          },
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: 'Failed to pick/upload image: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onChangePasswordPressed(
    SettingsChangePasswordPressed event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    if (changePassword == null) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: 'Change password not supported',
        ),
      );
      return;
    }
    
    final result = await changePassword!(
      ChangePasswordParams(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      ),
    );
    
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: 'Failed to change password: ${failure.message}',
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: SettingsStatus.success,
          successMessage: 'Password changed successfully',
        ),
      ),
    );
  }
}
