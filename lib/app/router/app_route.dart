enum AppRoute {
  login('/login'),
  adminLogin('/admin/login'),
  onboarding('/onboarding'),
  home('/'),
  search('/search'),
  profile('/profile'),
  publicProfile('/users/:id'),
  blocked('/profile/blocked'),
  inbox('/messages'),
  chat('/messages/:id'),
  notifications('/notifications'),
  createPost('/create'),
  editPost('/posts/edit'),
  adminDashboard('/admin');

  const AppRoute(this.path);
  final String path;
}
