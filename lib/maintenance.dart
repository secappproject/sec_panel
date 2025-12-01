import 'package:flutter/material.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart'; 

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  
  void _handleRefresh(BuildContext context) {
    
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing...'),
        duration: Duration(seconds: 1),
      ),
    );
    
  }

  
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                
                
                // Image.asset('assets/images/logo.jpeg', height: 32), 
                const SizedBox(height: 32),

                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.schneiderGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.handyman_rounded, 
                    size: 48, 
                    color: AppColors.schneiderGreen,
                  ),
                ),
                const SizedBox(height: 24), 

                
                const Text(
                  'We are currently under maintenance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.bold, 
                    fontSize: 28, 
                    color: Colors.black, 
                    letterSpacing: -0.5, 
                  ),
                ),
                const SizedBox(height: 8), 

                
                const Text(
                  'We are working hard to improve the user experience.\nPlease check back in a little while.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: Colors.grey, 
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32), 

                
                SizedBox(
                  width: double.infinity, 
                  child: Center(
                    child: SizedBox(
                      width: 200, 
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleRefresh(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.schneiderGreen, 
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), 
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: const Icon(Icons.refresh, size: 16), 
                        label: const Text(
                          'Refresh Page',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48), 

                
                Column(
                  children: [
                    const Text(
                      'Need access to other portals?',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 14,
                        color: Colors.grey, 
                      ),
                    ),
                    const SizedBox(height: 16), 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         // MVP Link (Commented out in your Next.js code, so commented here too)
                         /*
                         InkWell(
                           onTap: () => _launchURL('https://mvp-fe.vercel.app'),
                           child: const Text(
                             'MVP Portal',
                             style: TextStyle(
                               fontFamily: 'Lexend',
                               fontWeight: FontWeight.w500,
                               color: AppColors.schneiderGreen,
                               decoration: TextDecoration.underline,
                             ),
                           ),
                         ),
                         const SizedBox(width: 16),
                         */
                        
                        // Separator Dot
                        const Text(
                          '•', 
                          style: TextStyle(color: Colors.grey),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        
                        InkWell(
                          onTap: () => _launchURL('http://72.61.210.181'),
                          child: const Text(
                            'VRO',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.w500,
                              color: AppColors.schneiderGreen, 
                              decoration: TextDecoration.underline, 
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}