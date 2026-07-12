enum AppRoute {
  login('/login'),
  adminLogin('/admin/login'),
  onboarding('/onboarding'),
  home('/'),
  search('/search'),
  profile('/profile'),
  saved('/profile/saved'),
  publicProfile('/users/:id'),
  blocked('/profile/blocked'),
  inbox('/messages'),
  chat('/messages/:id'),
  notifications('/notifications'),
  premium('/premium'),
  settings('/settings'),
  changePassword('/settings/password'),
  postSummary('/posts/summary'),
  progress('/profile/progress'),
  support('/support'),
  shareAccount('/profile/share'),
  createPost('/create'),
  editPost('/posts/edit'),
  adminDashboard('/admin');

  const AppRoute(this.path);
  final String path;
}
