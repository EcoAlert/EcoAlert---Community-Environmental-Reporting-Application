import 'package:fixalert/citizen/report_issue_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() =>
      _MyReportsPageState();
}

class _MyReportsPageState
    extends State<MyReportsPage> {

  @override
  Widget build(BuildContext context) {

    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),

      appBar: AppBar(
        backgroundColor: const Color(0xFF7ECBA9),
        title: const Text("My Reports"),
      ),

      body: FutureBuilder(
        future: supabase
            .from('reports')
            .select()
            .eq(
              'user_id',
              supabase.auth.currentUser!.id,
            )
            .order(
              'created_at',
              ascending: false,
            ),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final reports = snapshot.data as List;

          if (reports.isEmpty) {
            return const Center(
              child: Text(
                "No reports submitted yet.",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            );
          }

          return Column(
  children: [

    Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),

      child: const Row(
        children: [

          Icon(
            Icons.info_outline,
            color: Colors.orange,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Reports cannot be edited after 6 hours. Please submit accurate information.',
            ),
          ),
        ],
      ),
    ),

    Expanded(
      child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,

            itemBuilder: (context, index) {

              final report = reports[index];

final createdAt =
    DateTime.parse(report['created_at']);

final canEdit =
    DateTime.now()
        .difference(createdAt)
        .inHours < 6;

print('NOW = ${DateTime.now()}');
print('CREATED = $createdAt');
print(
  'MINUTES = ${DateTime.now().difference(createdAt).inMinutes}',
);
print('canEdit = $canEdit');

              Color statusColor;


switch (report['status']) {
  case 'pending':
    statusColor = Colors.orange;
    break;

  case 'approved':
    statusColor = Colors.teal;
    break;

  case 'in_progress':
    statusColor = Colors.blue;
    break;

  case 'resolved':
    statusColor = Colors.green;
    break;

  case 'rejected':
    statusColor = Colors.red;
    break;

  default:
    statusColor = Colors.grey;
}

              return Container(
                margin: const EdgeInsets.only(bottom: 16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    if (report['image_url'] != null)

                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),

                        child: Image.network(
                          report['image_url'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Row(
  children: [

    Expanded(
      child: Text(
        report['category'] ?? "Issue",
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    if (report['status'] == 'pending')
      PopupMenuButton<String>(
        onSelected: (value) async {

          if (value == 'edit') {

  if (!canEdit) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Editing time has expired',
        ),
      ),
    );
    return;
  }
  final updated =
    await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) =>
        ReportIssuePage(
      report: report,
    ),
  ),
);

if (updated == true) {
  setState(() {});
}


} else if (value == 'delete') {

            final confirm =
                await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text(
                  'Delete Report?',
                ),
                content: const Text(
                  'Are you sure you want to delete this report?',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        false,
                      );
                    },
                    child: const Text(
                      'Cancel',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        true,
                      );
                    },
                    child: const Text(
                      'Delete',
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true) {
  try {
    await supabase
    .from('reports')
    .delete()
    .eq('id', report['id']);

setState(() {});

ScaffoldMessenger.of(context)
    .showSnackBar(
  const SnackBar(
    content: Text(
      'Report deleted',
    ),
  ),
);
  } catch (e) {
    print(e);

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          e.toString(),
        ),
      ),
    );
  }
}
          }
        },

        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text('Edit'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),
        ],
      ),

                              Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 5,
  ),

  decoration: BoxDecoration(
    color: statusColor.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(20),
  ),

  child: Text(
    report['status'].toString(),

    style: TextStyle(
      fontWeight: FontWeight.bold,
      color: statusColor,
    ),
  ),
)
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text(
                            report['description'] ??
                                "",
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [

                              const Icon(
                                Icons.location_on_outlined,
                                size: 18,
                              ),

                              const SizedBox(width: 5),

                              Expanded(
                                child: Text(
                                  report['location'] ??
                                      "Unknown",
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text(
                            report['created_at']
                                .toString()
                                .substring(0, 10),

                            style: TextStyle(
                              color:
                                  Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
                        },
          ),
        ),
      ],
    );
        },
      ),
    );
  }
}