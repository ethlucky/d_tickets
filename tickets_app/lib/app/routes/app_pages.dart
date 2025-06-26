import 'package:get/get.dart';
import '../pages/splash/splash_view.dart';
import '../pages/splash/splash_binding.dart';
import '../pages/home/home_view.dart';
import '../pages/home/home_binding.dart';
import '../pages/settings/settings_page.dart';
import '../pages/settings/settings_binding.dart';
import '../pages/event_detail/event_detail_view.dart';
import '../pages/event_detail/event_detail_binding.dart';

import '../pages/seat_detail/seat_detail_view.dart';
import '../pages/seat_detail/seat_detail_binding.dart';
import '../pages/seat_detail/seat_detail_demo.dart';
import '../pages/order_summary/order_summary_view.dart';
import '../pages/order_summary/order_summary_binding.dart';
import '../pages/order_summary/order_summary_demo.dart';
import '../pages/purchase_success/purchase_success_view.dart';
import '../pages/purchase_success/purchase_success_binding.dart';
import '../pages/purchase_success/purchase_success_demo.dart';
import '../pages/my_tickets/my_tickets_view.dart';
import '../pages/my_tickets/my_tickets_binding.dart';
import '../pages/my_tickets/my_tickets_demo.dart';
import '../pages/ticket_details/ticket_details_view.dart';
import '../pages/ticket_details/ticket_details_binding.dart';
import '../pages/ticket_details/ticket_details_demo.dart';
import '../pages/account_settings/account_settings_view.dart';
import '../pages/account_settings/account_settings_binding.dart';
import '../pages/account_settings/account_settings_demo.dart';
import '../pages/events/events_page.dart';
import '../pages/events/events_binding.dart';
import '../pages/search/search_page.dart';
import '../pages/search/search_binding.dart';
import '../pages/solana_wallet_demo/solana_wallet_demo_page.dart';
import '../pages/dapp_connection_request/dapp_connection_request_page.dart';
import '../pages/dapp_signature_request/dapp_signature_request_page.dart';
import 'app_routes.dart';

/// 应用页面配置
class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.eventDetail,
      page: () => const EventDetailView(),
      binding: EventDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.eventDetailDemo,
      page: () => const EventDetailView(),
      binding: EventDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.seatDetail,
      page: () => const SeatDetailView(),
      binding: SeatDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.seatDetailDemo,
      page: () => const SeatDetailDemo(),
      binding: SeatDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.orderSummary,
      page: () => const OrderSummaryView(),
      binding: OrderSummaryBinding(),
    ),
    GetPage(
      name: AppRoutes.orderSummaryDemo,
      page: () => const OrderSummaryDemo(),
      binding: OrderSummaryBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.purchaseSuccess,
      page: () => const PurchaseSuccessView(),
      binding: PurchaseSuccessBinding(),
    ),
    GetPage(
      name: AppRoutes.purchaseSuccessDemo,
      page: () => const PurchaseSuccessDemo(),
      binding: PurchaseSuccessBinding(),
    ),
    GetPage(
      name: AppRoutes.myTickets,
      page: () => const MyTicketsView(),
      binding: MyTicketsBinding(),
    ),
    GetPage(
      name: AppRoutes.myTicketsDemo,
      page: () => const MyTicketsDemo(),
      binding: MyTicketsBinding(),
    ),
    GetPage(
      name: AppRoutes.ticketDetails,
      page: () => const TicketDetailsView(),
      binding: TicketDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.ticketDetailsDemo,
      page: () => const TicketDetailsDemo(),
      binding: TicketDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.accountSettings,
      page: () => const AccountSettingsView(),
      binding: AccountSettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.accountSettingsDemo,
      page: () => const AccountSettingsDemo(),
      binding: AccountSettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.events,
      page: () => const EventsPage(),
      binding: EventsBinding(),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchPage(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: AppRoutes.solanaWalletDemo,
      page: () => const SolanaWalletDemoPage(),
    ),
    GetPage(
      name: AppRoutes.dappConnectionRequest,
      page: () => const DAppConnectionRequestPage(),
    ),
    GetPage(
      name: AppRoutes.dappSignatureRequest,
      page: () => const DAppSignatureRequestPage(),
    ),
  ];
}
