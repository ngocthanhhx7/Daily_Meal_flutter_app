enum AppRoute {
  login('/login'),
  adminLogin('/admin/login'),
  onboarding('/onboarding'),
  home('/'),
  adminDashboard('/admin');

  const AppRoute(this.path);
  final String path;
}
