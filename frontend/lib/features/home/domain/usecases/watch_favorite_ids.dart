// C-5 Fix: WatchFavoriteIds has been moved to the favorites domain where it semantically belongs.
// This re-export keeps existing HomeBloc imports compiling without changes.
export '../../../favorites/domain/usecases/watch_favorite_ids.dart';
