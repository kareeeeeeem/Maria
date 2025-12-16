
import 'package:churchapp/aus/login/login_screen.dart';
import 'package:churchapp/aus/signup/signup_screen.dart';
import 'package:churchapp/screens/ChurchInfoScreen.dart';
import 'package:churchapp/screens/FeastsPage.dart';
import 'package:churchapp/screens/HomePage.dart';
import 'package:churchapp/screens/bible/bible_page.dart';
import 'package:churchapp/screens/ChurchStore.dart';
import 'package:churchapp/screens/christian_bot_page.dart';
import 'package:churchapp/screens/libraryPage.dart';
import 'package:churchapp/aus/signup/MemberShipSignUp.dart';
import 'package:churchapp/screens/NewsPage.dart';
import 'package:churchapp/screens/ProfilePage.dart';
import 'package:churchapp/screens/Requests/AdminRequestsPage.dart';
import 'package:churchapp/screens/SundaySchoolManagement.dart';
import 'package:churchapp/screens/VisitationAndShepherding.dart';
import 'package:churchapp/screens/activities_page.dart';
import 'package:churchapp/screens/admin_page.dart';
import 'package:churchapp/screens/kareemEmda.dart';
import 'package:churchapp/screens/masses_page.dart';
import 'package:churchapp/screens/meetings_page.dart';
import 'package:churchapp/screens/notification/notification_screen.dart';
import 'package:churchapp/screens/notification/sendNotifiactions.dart';
import 'package:churchapp/screens/Requests/visitation_page.dart';
import 'package:churchapp/welcome/on_boarding/start_screen.dart';
import 'package:churchapp/welcome/on_boarding/on_boarding_screen.dart';
import 'package:churchapp/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';

final Map<String, WidgetBuilder> routes = {

        '/': (context) => const StartScreen(), 
        '/StartScreen': (context) => const StartScreen(), // الاحتفاظ به للمرجعية
        
        '/user_signup': (context) => const UserSignUpScreen(), 
        '/user_login': (context) => const UserLoginScreen(), 

        '/HomePage': (context) => const HomePage(), 

        '/bible': (context) => BibleFeaturePage(),
        // '/agpeya': (context) => const AgpeyaFeaturePage(),

        '/masses': (context) => const MassesPage(), 
        '/StorePage': (context) => const StorePage(), 
        '/InventoryPage': (context) => const InventoryPage(), 
        '/visit': (context) => const VisitationPage(), 
        '/service': (context) => const VisitationPage(), 
        '/meetings': (context) => const MeetingsPage(), 
        '/activities': (context) =>  const ActivitiesPage(), 
        '/events': (context) =>  const ActivitiesPage(), 
        '/news': (context) => const NewsPage(), 
        '/profile': (context) => const ProfilePage(), 
        '/admin': (context) => const AdminPage(), 
        '/OnBoardingScreen': (context) => const OnBoardingScreen(), 
        '/WelcomeScreen': (context) => const WelcomeScreen(), 
        '/ProfileSkeleton': (context) => const ProfileSkeleton(), 
        
        '/NotificationsPage': (context) => const NotificationsPage(), 
        '/AdminNotificationPage': (context) => const AdminNotificationPage(), 
        '/HowUsViewPage': (context) => const HowUsView(),

        '/MemberDataEntryScreen': (context) => const MemberDataEntryScreen(),
        '/VisitationScreen': (context) => const VisitationScreen(),
        '/SundaySchoolHome': (context) => const SundaySchoolHome(),
        '/AdminRequestsPage': (context) => const AdminRequestsPage(),
        '/feasts': (context) => const FeastsPage(),
        '/ChristianBotPage': (context) =>  ChristianBotPage(),
        '/ChurchInfoScreen': (context) =>  ChurchInfoScreen(),


        // '/DonationPage': (context) => const DonationPage(),
        // '/settings': (context) => const SettingsPage(), 
        // '/about': (context) => const ChurchInfoPage(), 
        


  
};
