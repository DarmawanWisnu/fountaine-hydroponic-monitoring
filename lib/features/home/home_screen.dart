import 'package:flutter/material.dart';
import 'package:fountaine/app/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 375.0;
    const bg = Color(0xFFF6FBF6);
    const primary = Color(0xFF154B2E);
    const muted = Color(0xFF7A7A7A);

    Widget featureCard({
      required String title,
      required String subtitle,
      required String assetImage, // path to image asset
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16 * s),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16 * s),
          ),
          padding: EdgeInsets.all(12 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18 * s,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
              SizedBox(height: 6 * s),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13 * s, color: muted),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12 * s),
                  child: Image.asset(
                    assetImage,
                    width: 110 * s,
                    height: 90 * s,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER HERO
            SizedBox(
              height: 180 * s,
              child: Stack(
                children: [
                  // hero background image (rounded bottom)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28 * s),
                      ),
                      child: Image.asset(
                        'assets/images/weather_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // top controls (left + right) — fixed at top
                  Positioned(
                    top: 12 * s,
                    left: 18 * s,
                    right: 18 * s,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white70,
                          radius: 20 * s,
                          child: IconButton(
                            icon: Icon(
                              Icons.grid_view_rounded,
                              color: primary,
                              size: 18 * s,
                            ),
                            onPressed: () {},
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20 * s,
                          child: IconButton(
                            icon: Icon(
                              Icons.notifications_none,
                              color: primary,
                              size: 18 * s,
                            ),
                            onPressed: () =>
                                Navigator.pushNamed(context, Routes.history),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // location block
                  Positioned(
                    top: 60 * s, // <-- ubah angka ini untuk cocokin ke Figma
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Your location',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12 * s,
                          ),
                        ),
                        SizedBox(height: 6 * s),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                              size: 16 * s,
                            ),
                            SizedBox(width: 6 * s),
                            Text(
                              'Tangerang, Banten',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16 * s,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Weather card overlapping
            Transform.translate(
              offset: Offset(0, -28 * s),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18 * s),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18 * s,
                    vertical: 18 * s,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16 * s),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '23°C',
                            style: TextStyle(
                              fontSize: 28 * s,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                          ),
                          SizedBox(height: 6 * s),
                          Text(
                            'Tangerang, Banten',
                            style: TextStyle(fontSize: 16 * s, color: primary),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Image.asset(
                        'assets/images/rain_icon.png',
                        width: 72 * s,
                        height: 72 * s,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 8 * s),

            // Section title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 22 * s),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'All Features',
                  style: TextStyle(
                    fontSize: 18 * s,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ),
            ),

            SizedBox(height: 12 * s),

            // Grid 2x2
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 18 * s,
                ).copyWith(bottom: 18 * s),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14 * s,
                  crossAxisSpacing: 12 * s,
                  childAspectRatio: 0.82,
                  children: [
                    featureCard(
                      title: 'Monitoring',
                      subtitle: 'Check your plant\'s health',
                      assetImage: 'assets/images/feature_monitor.png',
                      onTap: () => Navigator.pushNamed(context, Routes.monitor),
                    ),
                    featureCard(
                      title: 'Notification',
                      subtitle: 'View past records',
                      assetImage: 'assets/images/feature_notification.png',
                      onTap: () => Navigator.pushNamed(context, Routes.history),
                    ),
                    featureCard(
                      title: 'Add Kit',
                      subtitle: 'Connect new devices',
                      assetImage: 'assets/images/feature_addkit.png',
                      onTap: () => Navigator.pushNamed(context, Routes.addKit),
                    ),
                    featureCard(
                      title: 'Setting',
                      subtitle: 'Manage your account',
                      assetImage: 'assets/images/feature_setting.png',
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.settings),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom navigation with center QR button
      bottomNavigationBar: SizedBox(
        height: 84 * s,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // background rounded bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 64 * s,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(22 * s),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28 * s),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Home icon
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          Routes.home,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.home_outlined,
                              color: primary,
                              size: 26 * s,
                            ),
                            SizedBox(height: 6 * s),
                            Container(
                              width: 6 * s,
                              height: 6 * s,
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // People -> monitor
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.monitor),
                        child: Icon(
                          Icons.people_outline,
                          color: Colors.grey,
                          size: 26 * s,
                        ),
                      ),

                      // spacer for center button
                      SizedBox(width: 56 * s),

                      // Tree -> notification/history
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.history),
                        child: Icon(
                          Icons.park_outlined,
                          color: Colors.grey,
                          size: 26 * s,
                        ),
                      ),

                      // Profile -> settings
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.settings),
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.grey,
                          size: 26 * s,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // center floating QR button
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, Routes.addKit),
                child: Container(
                  width: 72 * s,
                  height: 72 * s,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.18),
                        blurRadius: 18 * s,
                        offset: Offset(0, 8 * s),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.qr_code_2,
                      color: Colors.white,
                      size: 30 * s,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
