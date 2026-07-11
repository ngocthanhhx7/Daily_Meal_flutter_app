enum AppRoute {
  login('/login'),
  adminLogin('/admin/login'),
  onboarding('/onboarding'),
  home('/'),
  search('/search'),
  profile('/profile'),
  publicProfile('/users/:id'),
  createPost('/create'),
  editPost('/posts/edit'),
  adminDashboard('/admin');

  const AppRoute(this.path);
  final String path;
}
