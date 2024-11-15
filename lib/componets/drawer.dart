import 'package:flutter/material.dart';
import 'package:minimal/pages/about_page.dart';
import 'package:minimal/pages/home_page.dart';
import 'package:minimal/pages/my_profile.dart';
import 'package:minimal/pages/upload_post_page.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
           DrawerHeader(
            decoration: const BoxDecoration(),
            
            child: Container(
                height:300,
                width:300,
                decoration:const BoxDecoration(
                  // shape:BoxShape.circle,
                  image: DecorationImage(image: AssetImage('assets/logo.png'),
                  // fit: BoxFit.contain,
                  
                  ),
                  
                ),
                ) 
                
          ),
          
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('HOME'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.post_add),
            title: const Text('CREATE POST'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UploadPostPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('PROFILE'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          // ListTile(
          //   leading: const Icon(Icons.podcasts),
          //   title: const Text('MY CONTENT'),
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const MyContentPage()),
          //     );
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.read_more),
            title: const Text('ABOUT'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
          
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('LOGOUT'),
            onTap: () {
              context.read<AuthService>().signOut();
            },
          ),
        ],
      ),
    );
  }
}
