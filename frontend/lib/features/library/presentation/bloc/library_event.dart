import 'package:equatable/equatable.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

class LibraryStarted extends LibraryEvent {
  final int initialTabIndex;
  const LibraryStarted({this.initialTabIndex = 0});

  @override
  List<Object?> get props => [initialTabIndex];
}

class LibraryTabChanged extends LibraryEvent {
  final int index;
  const LibraryTabChanged(this.index);

  @override
  List<Object?> get props => [index];
}

class LibraryDeleteUpload extends LibraryEvent {
  final String uploadId;
  const LibraryDeleteUpload(this.uploadId);

  @override
  List<Object?> get props => [uploadId];
}
