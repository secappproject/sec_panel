import 'package:secpanel/models/issue.dart';

class IssueWithComments {
  final Issue issue;
  final String panelNoPp;
  final List<IssueComment> comments;

  IssueWithComments({
    required this.issue,
    required this.panelNoPp,
    required this.comments,
  });

  factory IssueWithComments.fromJson(Map<String, dynamic> json) {
    return IssueWithComments(
      issue: Issue.fromJson(json['issue']),
      panelNoPp: json['panel_no_pp'] as String,
      comments: (json['comments'] as List)
          .map((c) => IssueComment.fromJson(c))
          .toList(),
    );
  }
}