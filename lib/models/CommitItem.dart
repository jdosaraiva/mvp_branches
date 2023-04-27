import 'package:mvp_branches/models/Commit.dart';

class CommitItem {
  final String title;
  bool selected;
  Commit commit;

  CommitItem({required this.title, required this.commit, this.selected = false});
}