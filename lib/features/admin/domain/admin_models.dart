enum AdminRange {
  oneDay('1d', '24 giờ'),
  sevenDays('7d', '7 ngày'),
  thirtyDays('30d', '30 ngày'),
  all('all', 'Tất cả');

  const AdminRange(this.wireValue, this.label);
  final String wireValue;
  final String label;
}

int _integer(Object? value) => value is num ? value.round() : 0;
double _number(Object? value) => value is num ? value.toDouble() : 0;
Map<String, dynamic> _map(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : const {};
List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
    : const [];

class AdminTotals {
  const AdminTotals({
    this.users = 0,
    this.posts = 0,
    this.meals = 0,
    this.comments = 0,
    this.likes = 0,
    this.saves = 0,
    this.payments = 0,
    this.revenue = 0,
    this.premiumUsers = 0,
    this.openReports = 0,
    this.hiddenPosts = 0,
  });

  factory AdminTotals.fromJson(Map<String, dynamic> json) => AdminTotals(
    users: _integer(json['users']),
    posts: _integer(json['posts']),
    meals: _integer(json['meals']),
    comments: _integer(json['comments']),
    likes: _integer(json['likes']),
    saves: _integer(json['saves']),
    payments: _integer(json['payments']),
    revenue: _number(json['revenue']),
    premiumUsers: _integer(json['premiumUsers']),
    openReports: _integer(json['openReports']),
    hiddenPosts: _integer(json['hiddenPosts']),
  );

  final int users, posts, meals, comments, likes, saves, payments;
  final double revenue;
  final int premiumUsers, openReports, hiddenPosts;
}

class AdminToday {
  const AdminToday({this.users = 0, this.posts = 0, this.interactions = 0});
  factory AdminToday.fromJson(Map<String, dynamic> json) => AdminToday(
    users: _integer(json['users']),
    posts: _integer(json['posts']),
    interactions: _integer(json['interactions']),
  );
  final int users, posts, interactions;
}

class AdminDailyPoint {
  const AdminDailyPoint({
    required this.date,
    this.users = 0,
    this.posts = 0,
    this.interactions = 0,
    this.payments = 0,
    this.revenue = 0,
    this.reports = 0,
    this.apiErrors = 0,
  });
  factory AdminDailyPoint.fromJson(Map<String, dynamic> json) =>
      AdminDailyPoint(
        date: json['date']?.toString() ?? '',
        users: _integer(json['users']),
        posts: _integer(json['posts']),
        interactions: _integer(json['interactions']),
        payments: _integer(json['payments']),
        revenue: _number(json['revenue']),
        reports: _integer(json['reports']),
        apiErrors: _integer(json['apiErrors']),
      );
  final String date;
  final int users, posts, interactions, payments, reports, apiErrors;
  final double revenue;
}

class AdminBreakdownItem {
  const AdminBreakdownItem(this.label, this.count);
  factory AdminBreakdownItem.fromJson(Map<String, dynamic> json) =>
      AdminBreakdownItem(
        json['_id']?.toString() ?? 'unknown',
        _integer(json['count']),
      );
  final String label;
  final int count;
}

class AdminBreakdowns {
  const AdminBreakdowns({
    this.usersByPremium = const [],
    this.postsByVisibility = const [],
    this.postsByModeration = const [],
    this.paymentsByStatus = const [],
    this.reportsByStatus = const [],
  });
  factory AdminBreakdowns.fromJson(Map<String, dynamic> json) =>
      AdminBreakdowns(
        usersByPremium: _items(json['usersByPremium']),
        postsByVisibility: _items(json['postsByVisibility']),
        postsByModeration: _items(json['postsByModeration']),
        paymentsByStatus: _items(json['paymentsByStatus']),
        reportsByStatus: _items(json['reportsByStatus']),
      );
  static List<AdminBreakdownItem> _items(Object? raw) =>
      _maps(raw).map(AdminBreakdownItem.fromJson).toList(growable: false);
  final List<AdminBreakdownItem> usersByPremium;
  final List<AdminBreakdownItem> postsByVisibility;
  final List<AdminBreakdownItem> postsByModeration;
  final List<AdminBreakdownItem> paymentsByStatus;
  final List<AdminBreakdownItem> reportsByStatus;
}

class AdminRecentItem {
  const AdminRecentItem({
    required this.id,
    required this.kind,
    required this.data,
  });
  final String id;
  final String kind;
  final Map<String, dynamic> data;
}

class AdminKpiAnalytics {
  const AdminKpiAnalytics({
    this.dau = 0,
    this.wau = 0,
    this.mau = 0,
    this.returning = 0,
    this.averageSessionDurationMs = 0,
    this.bounceRate = 0,
    this.feedCtr = 0,
    this.averageScrollDepth = 0,
    this.averageApiResponseMs = 0,
    this.averageImageLoadMs = 0,
    this.runtimeErrors = 0,
    this.crashRate = 0,
    this.creatorConversionRate = 0,
    this.postCompletionRate = 0,
    this.mealCompletionRate = 0,
    this.paymentCompletionRate = 0,
  });

  factory AdminKpiAnalytics.fromJson(Map<String, dynamic> json) {
    final active = _map(json['activeUsers']);
    final sessions = _map(json['sessions']);
    final feed = _map(json['feed']);
    final technical = _map(json['technical']);
    final creator = _map(json['creatorConversion']);
    final post = _map(json['postCreation']);
    final meal = _map(json['mealAnalysis']);
    final premium = _map(json['premiumFunnel']);
    return AdminKpiAnalytics(
      dau: _integer(active['dau']),
      wau: _integer(active['wau']),
      mau: _integer(active['mau']),
      returning: _integer(active['returning']),
      averageSessionDurationMs: _number(sessions['averageDurationMs']),
      bounceRate: _number(sessions['bounceRate']),
      feedCtr: _number(feed['ctr']),
      averageScrollDepth: _number(feed['averageScrollDepth']),
      averageApiResponseMs: _number(technical['averageApiResponseMs']),
      averageImageLoadMs: _number(technical['averageImageLoadMs']),
      runtimeErrors: _integer(technical['runtimeErrors']),
      crashRate: _number(technical['crashRate']),
      creatorConversionRate: _number(creator['rate']),
      postCompletionRate: _number(post['completionRate']),
      mealCompletionRate: _number(meal['completionRate']),
      paymentCompletionRate: _number(premium['paymentCompletionRate']),
    );
  }

  final int dau, wau, mau, returning, runtimeErrors;
  final double averageSessionDurationMs,
      bounceRate,
      feedCtr,
      averageScrollDepth,
      averageApiResponseMs,
      averageImageLoadMs,
      crashRate,
      creatorConversionRate,
      postCompletionRate,
      mealCompletionRate,
      paymentCompletionRate;
}

class AdminDashboard {
  const AdminDashboard({
    required this.range,
    required this.allTime,
    required this.inRange,
    required this.today,
    required this.daily,
    required this.breakdowns,
    required this.recent,
    this.analytics = const AdminKpiAnalytics(),
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    final recentJson = _map(json['recent']);
    final recent = <AdminRecentItem>[];
    for (final kind in ['reports', 'posts', 'payments', 'audit']) {
      for (final item in _maps(recentJson[kind])) {
        recent.add(
          AdminRecentItem(
            id: item['id']?.toString() ?? '',
            kind: kind,
            data: item,
          ),
        );
      }
    }
    return AdminDashboard(
      range: json['rangePreset']?.toString() ?? '7d',
      allTime: AdminTotals.fromJson(_map(json['totalsAllTime'])),
      inRange: AdminTotals.fromJson(_map(json['totalsInRange'])),
      today: AdminToday.fromJson(_map(json['today'])),
      daily: _maps(
        _map(json['charts'])['daily'],
      ).map(AdminDailyPoint.fromJson).toList(growable: false),
      breakdowns: AdminBreakdowns.fromJson(_map(json['breakdowns'])),
      analytics: AdminKpiAnalytics.fromJson(_map(json['analytics'])),
      recent: recent,
    );
  }

  final String range;
  final AdminTotals allTime, inRange;
  final AdminToday today;
  final List<AdminDailyPoint> daily;
  final AdminBreakdowns breakdowns;
  final AdminKpiAnalytics analytics;
  final List<AdminRecentItem> recent;
}

class AdminPage<T> {
  const AdminPage({
    required this.items,
    required this.page,
    required this.pages,
    required this.total,
  });
  final List<T> items;
  final int page, pages, total;
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.avatarUrl,
    this.isPremium = false,
    this.createdAt,
  });
  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['id']?.toString() ?? '',
    name: json['displayName']?.toString() ?? 'Người dùng',
    email: json['email']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    avatarUrl: json['avatarUrl']?.toString(),
    isPremium: json['isPremium'] == true,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );
  final String id, name, email, phone;
  final String? avatarUrl;
  final bool isPremium;
  final DateTime? createdAt;
}

class AdminPost {
  const AdminPost({
    required this.id,
    required this.caption,
    required this.visibility,
    required this.moderationStatus,
    this.moderationReason = '',
    this.authorName = '',
    this.authorEmail = '',
    this.authorAvatarUrl,
    this.mediaType = 'image',
    this.imageUrls = const [],
    this.videoUrl,
    this.likes = 0,
    this.comments = 0,
    this.saves = 0,
    this.createdAt,
  });
  factory AdminPost.fromJson(Map<String, dynamic> json) {
    final stats = _map(json['stats']);
    final author = _map(json['author']);
    final video = _map(json['video']);
    return AdminPost(
      id: json['id']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      visibility: json['visibility']?.toString() ?? 'public',
      moderationStatus: json['moderationStatus']?.toString() ?? 'visible',
      moderationReason: json['moderationReason']?.toString() ?? '',
      authorName: author['displayName']?.toString() ?? '',
      authorEmail: author['email']?.toString() ?? '',
      authorAvatarUrl: author['avatarUrl']?.toString(),
      mediaType: json['mediaType']?.toString() ?? 'image',
      imageUrls: _maps(json['images'])
          .map((image) => image['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList(growable: false),
      videoUrl: video['url']?.toString(),
      likes: _integer(stats['likes']),
      comments: _integer(stats['comments']),
      saves: _integer(stats['saves']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
  final String id,
      caption,
      visibility,
      moderationStatus,
      moderationReason,
      authorName,
      authorEmail,
      mediaType;
  final String? authorAvatarUrl, videoUrl;
  final List<String> imageUrls;
  final int likes, comments, saves;
  int get interactions => likes + comments + saves;
  int get imageCount => imageUrls.length;
  final DateTime? createdAt;
}

class AdminReport {
  const AdminReport({
    required this.id,
    required this.note,
    required this.status,
    this.adminNote = '',
    this.actorName = '',
    this.targetName = '',
    this.createdAt,
  });
  factory AdminReport.fromJson(Map<String, dynamic> json) => AdminReport(
    id: json['id']?.toString() ?? '',
    note: json['note']?.toString() ?? '',
    status: json['status']?.toString() ?? 'open',
    adminNote: json['adminNote']?.toString() ?? '',
    actorName: _map(json['actor'])['displayName']?.toString() ?? '',
    targetName: _map(json['target'])['displayName']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );
  final String id, note, status, adminNote, actorName, targetName;
  final DateTime? createdAt;
}

class AdminPayment {
  const AdminPayment({
    required this.id,
    required this.planId,
    required this.orderCode,
    required this.amount,
    required this.currency,
    required this.status,
    this.userName = '',
    this.createdAt,
  });
  factory AdminPayment.fromJson(Map<String, dynamic> json) => AdminPayment(
    id: json['id']?.toString() ?? '',
    planId: json['planId']?.toString() ?? '',
    orderCode: _integer(json['orderCode']),
    amount: _number(json['amount']),
    currency: json['currency']?.toString() ?? 'VND',
    status: json['status']?.toString() ?? '',
    userName: _map(json['user'])['displayName']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );
  final String id, planId, currency, status, userName;
  final int orderCode;
  final double amount;
  final DateTime? createdAt;
}

AdminPage<T> adminPage<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) decode,
) {
  final pagination = _map(json['pagination']);
  return AdminPage(
    items: _maps(json[key]).map(decode).toList(growable: false),
    page: _integer(pagination['page']),
    pages: _integer(pagination['pages']),
    total: _integer(pagination['total']),
  );
}

class AdminHourlyPoint {
  const AdminHourlyPoint({
    required this.hour,
    required this.label,
    this.activeUsers = 0,
    this.events = 0,
    this.posts = 0,
    this.interactions = 0,
    this.likes = 0,
    this.saves = 0,
    this.comments = 0,
    this.reportsOpened = 0,
    this.payments = 0,
    this.paymentFailed = 0,
    this.revenue = 0,
    this.aiMealUsage = 0,
  });
  factory AdminHourlyPoint.fromJson(Map<String, dynamic> json) =>
      AdminHourlyPoint(
        hour: _integer(json['hour']),
        label: json['label']?.toString() ?? '',
        activeUsers: _integer(json['activeUsers']),
        events: _integer(json['events']),
        posts: _integer(json['posts']),
        interactions: _integer(json['interactions']),
        likes: _integer(json['likes']),
        saves: _integer(json['saves']),
        comments: _integer(json['comments']),
        reportsOpened: _integer(json['reportsOpened']),
        payments: _integer(json['payments']),
        paymentFailed: _integer(json['paymentFailed']),
        revenue: _number(json['revenue']),
        aiMealUsage: _integer(json['aiMealUsage']),
      );
  final int hour,
      activeUsers,
      events,
      posts,
      interactions,
      likes,
      saves,
      comments,
      reportsOpened,
      payments,
      paymentFailed,
      aiMealUsage;
  final String label;
  final double revenue;
}

class AdminAnalytics24h {
  const AdminAnalytics24h({
    required this.summary,
    required this.hourly,
    this.range = const {},
    this.interactionBreakdown = const [],
    this.aiFunnel = const {},
    this.sourceTraffic = const [],
    this.paymentMetrics = const {},
    this.reportMetrics = const {},
    this.tables = const {},
  });
  factory AdminAnalytics24h.fromJson(Map<String, dynamic> json) =>
      AdminAnalytics24h(
        range: _map(json['range']),
        summary: _map(json['summary']),
        hourly: _maps(
          json['hourly'],
        ).map(AdminHourlyPoint.fromJson).toList(growable: false),
        interactionBreakdown: _maps(json['interactionBreakdown']),
        aiFunnel: _map(json['aiFunnel']),
        sourceTraffic: _maps(json['sourceTraffic']),
        paymentMetrics: _map(json['paymentMetrics']),
        reportMetrics: _map(json['reportMetrics']),
        tables: _map(json['tables']),
      );
  final Map<String, dynamic> range, summary;
  final List<AdminHourlyPoint> hourly;
  final List<Map<String, dynamic>> interactionBreakdown, sourceTraffic;
  final Map<String, dynamic> aiFunnel, paymentMetrics, reportMetrics, tables;
}

class AdminHeatmapCell {
  const AdminHeatmapCell({
    required this.day,
    required this.weekday,
    required this.hour,
    required this.value,
  });
  factory AdminHeatmapCell.fromJson(Map<String, dynamic> json) =>
      AdminHeatmapCell(
        day: json['day']?.toString() ?? '',
        weekday: json['weekday']?.toString() ?? '',
        hour: _integer(json['hour']),
        value: _integer(json['value']),
      );
  final String day, weekday;
  final int hour, value;
}

class AdminHeatmap {
  const AdminHeatmap({required this.metric, required this.cells});
  factory AdminHeatmap.fromJson(Map<String, dynamic> json) => AdminHeatmap(
    metric: json['metric']?.toString() ?? 'events',
    cells: _maps(
      json['cells'],
    ).map(AdminHeatmapCell.fromJson).toList(growable: false),
  );
  final String metric;
  final List<AdminHeatmapCell> cells;
}

class AdminAiReport {
  const AdminAiReport({
    required this.title,
    required this.executiveSummary,
    required this.sections,
    required this.priorityActions,
    required this.generatedAt,
  });
  factory AdminAiReport.fromJson(Map<String, dynamic> json) {
    final report = _map(json['report']);
    return AdminAiReport(
      title: report['title']?.toString() ?? 'Báo cáo AI',
      executiveSummary: _strings(report['executiveSummary']),
      sections: _maps(report['sections']),
      priorityActions: _strings(report['priorityActions']),
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? ''),
    );
  }
  static List<String> _strings(Object? value) => value is List
      ? value.map((e) => e.toString()).toList(growable: false)
      : const [];
  final String title;
  final List<String> executiveSummary, priorityActions;
  final List<Map<String, dynamic>> sections;
  final DateTime? generatedAt;
}
