enum AppRoute {
  login('/login'),
  adminLogin('/admin/login'),
  onboarding('/onboarding'),
  home('/'),
  search('/search'),
  createPost('/create'),
  editPost('/posts/edit'),
  adminDashboard('/admin');

  const AppRoute(this.path);
  final String path;
}
