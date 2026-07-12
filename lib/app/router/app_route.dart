enum AppRoute {
  login('/login'),
  adminLogin('/admin/login'),
  onboarding('/onboarding'),
  home('/'),
  search('/search'),
  profile('/profile'),
  editProfile('/profile/edit'),
  saved('/profile/saved'),
  publicProfile('/users/:id'),
  follows('/users/:id/follows'),
  blocked('/profile/blocked'),
  inbox('/messages'),
  chat('/messages/:id'),
  notifications('/notifications'),
  comments('/posts/:id/comments'),
  recipe('/posts/:id/recipe'),
  premium('/premium'),
  settings('/settings'),
  changePassword('/settings/password'),
  postSummary('/posts/summary'),
  progress('/profile/progress'),
  support('/support'),
  shareAccount('/profile/share'),
  createPost('/create'),
  editPost('/posts/:id/edit'),
  adminDashboard('/admin'),
  adminUsers('/admin/users'),
  adminUserDetail('/admin/users/:id');

  const AppRoute(this.path);
  final String path;
}
