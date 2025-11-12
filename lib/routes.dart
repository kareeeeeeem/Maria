
import 'package:churchapp/aus/login/login_screen.dart';
import 'package:churchapp/aus/signup/signup_screen.dart';
import 'package:churchapp/const/complete_profile_screen.dart';
import 'package:churchapp/screens/ChurchStore.dart';
import 'package:churchapp/screens/InventoryPage.dart';
import 'package:churchapp/screens/NewsPage.dart';
import 'package:churchapp/screens/ProfilePage.dart';
import 'package:churchapp/screens/activities_page.dart';
import 'package:churchapp/screens/admin_page.dart';
import 'package:churchapp/screens/church_info_page.dart';
import 'package:churchapp/screens/home_page.dart';
import 'package:churchapp/screens/kareemEmda.dart';
import 'package:churchapp/screens/masses_page.dart';
import 'package:churchapp/screens/meetings_page.dart';
import 'package:churchapp/screens/notification/notification_screen.dart';
import 'package:churchapp/screens/notification/sendNotifiactions.dart';
import 'package:churchapp/screens/settings_page.dart';
import 'package:churchapp/screens/sunday_school_page.dart';
import 'package:churchapp/screens/visitation_page.dart';
import 'package:churchapp/welcome/on_boarding/start_screen.dart';
import 'package:churchapp/welcome/on_boarding/on_boarding_screen.dart';
import 'package:churchapp/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';

final Map<String, WidgetBuilder> routes = {

        '/': (context) => const StartScreen(), // <= هذا هو العنصر المفقود!
        '/HomePage': (context) => const HomePage(), 
        '/StartScreen': (context) => const StartScreen(), // هذا المسار مكرر الآن، لكن يُفضل الاحتفاظ بـ '/' للمسار الأولي

        '/masses': (context) => const MassesPage(), 
         '/SundaySchoolPage': (context) => const SundaySchoolPage(), 
        '/StorePage': (context) => const StorePage(), 
        '/InventoryPage': (context) => const InventoryPage(), 

        '/visit': (context) => const VisitationPage(), 
        '/service': (context) => const VisitationPage(), 
        '/meetings': (context) => const MeetingsPage(), 
        '/activities': (context) =>  ActivitiesPage(), 
        '/events': (context) =>  ActivitiesPage(), 
        '/about': (context) => const ChurchInfoPage(), 
        '/news': (context) => const NewsPage(), 
        '/profile': (context) => const ProfilePage(), 
        '/settings': (context) => const SettingsPage(), 
        '/admin': (context) => const AdminPage(), 
        '/OnBoardingScreen': (context) => const OnBoardingScreen(), 
        '/WelcomeScreen': (context) => const WelcomeScreen(), 
        '/YourGoalScreen': (context) => const YourGoalScreen(), 
        '/UserLoginScreen': (context) => const UserLoginScreen(), 
        '/UserSignUpScreen': (context) => const UserSignUpScreen(), 
        '/CompleteProfileScreen': (context) => const CompleteProfileScreen(), 
        '/ProfileSkeleton': (context) => const ProfileSkeleton(), 
        
        '/NotificationsPage': (context) => const NotificationsPage(), 
        '/AdminNotificationPage': (context) => const AdminNotificationPage(), 



        
  
};
