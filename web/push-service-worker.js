self.addEventListener('push', (event) => {
  let payload = {};
  try { payload = event.data ? event.data.json() : {}; } catch (_) {}
  event.waitUntil(self.registration.showNotification(payload.title || 'Daily Meal', {
    body: payload.body || '',
    icon: payload.icon || 'icons/Icon-192.png',
    badge: payload.badge || 'favicon.png',
    data: payload.data || {},
  }));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const target = event.notification.data?.url || '/?screen=Notifications';
  event.waitUntil(clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windows) => {
    for (const windowClient of windows) {
      if ('focus' in windowClient) {
        windowClient.navigate(target);
        return windowClient.focus();
      }
    }
    return clients.openWindow ? clients.openWindow(target) : undefined;
  }));
});
