import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';

@lazySingleton
class ShareSheet {
  Future<void> share(String text) async {
    await SharePlus.instance.share(new ShareParams(text: text));
  }
}
