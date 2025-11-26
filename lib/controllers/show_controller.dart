import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trakt/trakt_show.dart';
import '../services/trakt/trakt_client.dart';
import '../core/config/trakt_config.dart';

final traktClientProvider = Provider<TraktClient>((ref) {
  return TraktClient();
});

final showDetailsProvider = FutureProvider.autoDispose.family<TraktShow, String>((ref, slug) async {
  final client = ref.watch(traktClientProvider);
  return await client.shows.getSummary(slug, extended: TraktExtended.full);
});
