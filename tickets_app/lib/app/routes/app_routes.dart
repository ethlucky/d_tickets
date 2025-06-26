/// 应用路由管理
class AppRoutes {
  // 路由名称常量
  static const String home = '/';
  static const String splash = '/splash';
  static const String wallet = '/wallet';
  static const String tickets = '/tickets';
  static const String ticketDetail = '/ticket-detail';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String themeSettings = '/theme-settings';
  static const String languageSettings = '/language-settings';
  static const String about = '/about';
  static const String eventDetail = '/event-detail';
  static const String eventDetailDemo = '/event-detail-demo';

  static const String seatDetail = '/seat-detail';
  static const String seatDetailDemo = '/seat-detail-demo';
  static const String orderSummary = '/order-summary';
  static const String orderSummaryDemo = '/order-summary-demo';

  static const String purchaseSuccess = '/purchase-success';
  static const String purchaseSuccessDemo = '/purchase-success-demo';
  static const String myTickets = '/my-tickets';
  static const String myTicketsDemo = '/my-tickets-demo';
  static const String ticketDetails = '/ticket-details';
  static const String ticketDetailsDemo = '/ticket-details-demo';
  static const String accountSettings = '/account-settings';
  static const String accountSettingsDemo = '/account-settings-demo';
  static const String events = '/events';
  static const String search = '/search';

  // Solana Mobile Wallet Adapter 路由
  static const String solanaWalletDemo = '/solana-wallet-demo';
  static const String dappConnectionRequest = '/dapp-connection-request';
  static const String dappSignatureRequest = '/dapp-signature-request';

  // 获取所有路由
  static String getHomeRoute() => home;
  static String getSplashRoute() => splash;
  static String getWalletRoute() => wallet;
  static String getTicketsRoute() => tickets;
  static String getTicketDetailRoute(String ticketId) =>
      '$ticketDetail?id=$ticketId';
  static String getProfileRoute() => profile;
  static String getSettingsRoute() => settings;
  static String getThemeSettingsRoute() => themeSettings;
  static String getLanguageSettingsRoute() => languageSettings;
  static String getAboutRoute() => about;
  static String getEventDetailRoute(String eventId) =>
      '$eventDetail?id=$eventId';
  static String getEventDetailDemoRoute() => eventDetailDemo;

  static String getSeatDetailRoute({
    required String seatStatusMapPDA,
    String? eventPda,
    String? ticketTypeName,
    String? areaId,
  }) {
    var route = '$seatDetail?seatStatusMapPDA=$seatStatusMapPDA';
    if (eventPda != null) route += '&eventPda=$eventPda';
    if (ticketTypeName != null) route += '&ticketTypeName=$ticketTypeName';
    if (areaId != null) route += '&areaId=$areaId';
    return route;
  }

  static String getSeatDetailDemoRoute() => seatDetailDemo;

  static String getOrderSummaryRoute() => orderSummary;
  static String getOrderSummaryDemoRoute() => orderSummaryDemo;

  static String getPurchaseSuccessRoute() => purchaseSuccess;
  static String getPurchaseSuccessDemoRoute() => purchaseSuccessDemo;
  static String getMyTicketsRoute() => myTickets;
  static String getMyTicketsDemoRoute() => myTicketsDemo;
  static String getTicketDetailsRoute(String ticketId) =>
      '$ticketDetails?id=$ticketId';
  static String getTicketDetailsDemoRoute() => ticketDetailsDemo;
  static String getAccountSettingsRoute() => accountSettings;
  static String getAccountSettingsDemoRoute() => accountSettingsDemo;
  static String getEventsRoute() => events;
  static String getSearchRoute() => search;

  // Solana Mobile Wallet Adapter 路由获取方法
  static String getSolanaWalletDemoRoute() => solanaWalletDemo;
  static String getDappConnectionRequestRoute() => dappConnectionRequest;
  static String getDappSignatureRequestRoute() => dappSignatureRequest;
}
