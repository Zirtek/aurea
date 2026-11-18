window.AureaPush = {
  // Inserisci qui la tua VAPID Public Key generata nello Step 2
  vapidPublicKey: 'BFEMkPWQECSj49-T6TatKhfiJvIentH1cyGhFTs9J4cJ570cEQcRumvtyhGxLSfHW8v20mEc9dehnxTJUvPZ3aQ',

  getEnvironmentInfo: function () {
    const ua = window.navigator.userAgent || '';
    const isIOS = /iPad|iPhone|iPod/.test(ua) ||
      (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
    const isStandalone = window.navigator.standalone === true ||
      window.matchMedia('(display-mode: standalone)').matches;
    const isSupported = 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
    const permission = ('Notification' in window) ? Notification.permission : 'unsupported';

    return JSON.stringify({
      isIOS,
      isStandalone,
      isSupported,
      permission,
    });
  },

  subscribe: async function () {
    if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
      throw new Error('PushManager non disponibile. Su iOS aggiungi prima l\'app alla schermata Home.');
    }

    const permission = await Notification.requestPermission();
    if (permission !== 'granted') {
      throw new Error('Permesso notifiche negato dall\'utente.');
    }

    const registration = await navigator.serviceWorker.register('/push-sw.js', {
      scope: '/aurea-push/',
    });
    await navigator.serviceWorker.ready;

    let subscription = await registration.pushManager.getSubscription();
    if (!subscription) {
      subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this._urlBase64ToUint8Array(this.vapidPublicKey),
      });
    }

    return JSON.stringify(subscription.toJSON());
  },

  getCurrentSubscription: async function () {
    if (!('serviceWorker' in navigator) || !('PushManager' in window)) return '';
    const registration = await navigator.serviceWorker.getRegistration('/aurea-push/');
    if (!registration) return '';
    const sub = await registration.pushManager.getSubscription();
    return sub ? JSON.stringify(sub.toJSON()) : '';
  },

  unsubscribe: async function () {
    if (!('serviceWorker' in navigator)) return;
    const registration = await navigator.serviceWorker.getRegistration('/aurea-push/');
    if (!registration) return;
    const sub = await registration.pushManager.getSubscription();
    if (sub) {
      await sub.unsubscribe();
    }
  },

  _urlBase64ToUint8Array: function (base64String) {
    const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);
    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  }
};