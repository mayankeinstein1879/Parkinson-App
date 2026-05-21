import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1050) {
          return const _HelpDesktopScreen();
        }
        return const _HelpMobileScreen();
      },
    );
  }
}

class _HelpDesktopScreen extends StatefulWidget {
  const _HelpDesktopScreen();

  @override
  State<_HelpDesktopScreen> createState() => _HelpDesktopScreenState();
}

class _HelpDesktopScreenState extends State<_HelpDesktopScreen> {
  int _activeTabIndex = 0;

  final List<String> _tabs = [
    'APP FEATURE DIRECTORY',
    'System Overview',
    'Hardware Status',
    'Adaptive Gait Cueing',
    'Emergency Protocols',
    'AI Analytics',
    'BLE Connection',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const _HelpSidebar(),
          Container(width: 1, color: AppColors.divider),
          _HelpTabListPanel(
            activeIndex: _activeTabIndex,
            tabs: _tabs,
            onTabSelected: (index) {
              setState(() {
                _activeTabIndex = index;
              });
            },
          ),
          Container(width: 1, color: AppColors.divider),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top status bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Live Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF142E2B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0x6600FF88),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Live Status: ',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'All Sensors Active',
                                style: GoogleFonts.inter(
                                  color: AppColors.accentGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // BLE Button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF11253E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryCyan.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bluetooth, color: AppColors.primaryCyan, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'BLE',
                                style: GoogleFonts.orbitron(
                                  color: AppColors.primaryCyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Screen Title & Description
                    Text(
                      _activeTabIndex == 0
                          ? 'SMART INSOLE APP FEATURE DIRECTORY'
                          : _tabs[_activeTabIndex].toUpperCase(),
                      style: GoogleFonts.orbitron(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _activeTabIndex == 0
                          ? 'A comprehensive guide to all available system functions.'
                          : 'Overview and guidelines for ${_tabs[_activeTabIndex]}.',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Detail Content
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildTabContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return const _AppFeatureDirectoryView();
      case 1:
        return const _SystemOverviewCard();
      case 2:
        return const _MonitoringGuideCard();
      case 3:
        return const _AdaptiveCueGuideCard();
      case 4:
        return const _EmergencyFeaturesCard();
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _AnalyticsExplanationCard(),
            SizedBox(height: 14),
            _AssistantTipsCard(),
          ],
        );
      case 6:
        return const _BleGuideCard();
      default:
        return const _AppFeatureDirectoryView();
    }
  }
}

class _HelpMobileScreen extends StatefulWidget {
  const _HelpMobileScreen();

  @override
  State<_HelpMobileScreen> createState() => _HelpMobileScreenState();
}

class _HelpMobileScreenState extends State<_HelpMobileScreen> {
  int _activeTabIndex = 0;

  final List<String> _tabs = [
    'APP FEATURE DIRECTORY',
    'System Overview',
    'Hardware Status',
    'Adaptive Gait Cueing',
    'Emergency Protocols',
    'AI Analytics',
    'BLE Connection',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'System Intelligence Hub',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Horizontal tabs for mobile
          Container(
            height: 48,
            color: AppColors.surface,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final isSelected = _activeTabIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _activeTabIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryCyan.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryCyan : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _tabs[index],
                          style: GoogleFonts.inter(
                            color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Tab Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _activeTabIndex == 0
                        ? 'SMART INSOLE APP FEATURE DIRECTORY'
                        : _tabs[_activeTabIndex].toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _activeTabIndex == 0
                        ? 'A comprehensive guide to all available system functions.'
                        : 'Overview and guidelines for ${_tabs[_activeTabIndex]}.',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTabContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_activeTabIndex == 0) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossCount = constraints.maxWidth > 600 ? 2 : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 80,
            ),
            itemCount: _features.length,
            itemBuilder: (context, index) {
              final feature = _features[index];
              final isCyan = index.isEven;
              final color = isCyan ? AppColors.primaryCyan : AppColors.secondaryPurple;
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.35),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1E35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color.withOpacity(0.6),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: _CustomFeatureIcon(
                          index: index,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            feature.title,
                            style: GoogleFonts.orbitron(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            feature.description,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    switch (_activeTabIndex) {
      case 1:
        return const _SystemOverviewCard();
      case 2:
        return const _MonitoringGuideCard();
      case 3:
        return const _AdaptiveCueGuideCard();
      case 4:
        return const _EmergencyFeaturesCard();
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _AnalyticsExplanationCard(),
            SizedBox(height: 14),
            _AssistantTipsCard(),
          ],
        );
      case 6:
        return const _BleGuideCard();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _HelpSidebar extends StatelessWidget {
  const _HelpSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: AppColors.cardBackground,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Brand Logo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primaryCyan, AppColors.secondaryPurple],
              ),
              boxShadow: [
                BoxShadow(color: AppColors.glowCyan, blurRadius: 10),
              ],
            ),
            child: const Center(
              child: Icon(Icons.circle_outlined, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(height: 40),
          _HelpSidebarIcon(
            icon: Icons.grid_view_rounded,
            active: false,
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          _HelpSidebarIcon(
            icon: Icons.analytics_outlined,
            active: false,
            onTap: () => Navigator.pushReplacementNamed(context, '/analytics'),
          ),
          _HelpSidebarIcon(
            icon: Icons.monitor_heart_outlined,
            active: false,
            onTap: () => Navigator.pushNamed(context, '/status'),
          ),
          _HelpSidebarIcon(
            icon: Icons.settings_outlined,
            active: false,
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          const Spacer(),
          // Logout button
          _HelpSidebarIcon(
            icon: Icons.logout_rounded,
            active: false,
            onTap: () => Navigator.pushReplacementNamed(context, '/auth'),
          ),
          // Active help icon at the very bottom
          _HelpSidebarIcon(
            icon: Icons.help_outline_rounded,
            active: true,
            onTap: () {},
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HelpSidebarIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _HelpSidebarIcon({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: active ? Border.all(color: AppColors.primaryCyan.withOpacity(0.6)) : null,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.glowCyan.withOpacity(0.28),
                      blurRadius: 14,
                      spreadRadius: -1,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: active ? AppColors.primaryCyan : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HelpTabListPanel extends StatelessWidget {
  final int activeIndex;
  final List<String> tabs;
  final ValueChanged<int> onTabSelected;

  const _HelpTabListPanel({
    required this.activeIndex,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App Feature Catalog label
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.secondaryPurple.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              'App Feature Catalog',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Vertical list of tabs
          Expanded(
            child: ListView.builder(
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final isSelected = activeIndex == index;
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => onTabSelected(index),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF13283A) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryCyan : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.glowCyan.withOpacity(0.15),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          tabs[index],
                          style: GoogleFonts.orbitron(
                            color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => onTabSelected(index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF152238) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: AppColors.primaryCyan.withOpacity(0.5))
                            : null,
                      ),
                      child: Text(
                        tabs[index],
                        style: GoogleFonts.inter(
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String description;
  final IconData icon;

  const _FeatureItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

final List<_FeatureItem> _features = [
  const _FeatureItem(
    title: 'Visual Laser Guide',
    description: 'Directed laser point on walking surfaces.',
    icon: Icons.gps_fixed,
  ),
  const _FeatureItem(
    title: 'Emergency Photiocation',
    description: 'Sensor and device health management.',
    icon: Icons.local_hospital_outlined,
  ),
  const _FeatureItem(
    title: 'Adaptive Gait Cueing',
    description: 'Automatic physical and visual walking cues.',
    icon: Icons.directions_run_outlined,
  ),
  const _FeatureItem(
    title: 'FOG Prediction',
    description: 'Stride metrics and symmetry tracking.',
    icon: Icons.stacked_line_chart,
  ),
  const _FeatureItem(
    title: 'Gait Analysis',
    description: 'Stride metrics and symmetry tracking.',
    icon: Icons.accessibility_new_rounded,
  ),
  const _FeatureItem(
    title: 'Emergency Protocols',
    description: 'Fall detection and SOS trigger.',
    icon: Icons.warning_amber_rounded,
  ),
  const _FeatureItem(
    title: 'FOG Prediction',
    description: 'Freezing of Gait risk assessment.',
    icon: Icons.report_problem_outlined,
  ),
  const _FeatureItem(
    title: 'AI Analytics',
    description: 'Historical health reports and trends.',
    icon: Icons.trending_up_rounded,
  ),
  const _FeatureItem(
    title: 'Gait Cuaction',
    description: 'Historical health reports and trends.',
    icon: Icons.waves_rounded,
  ),
  const _FeatureItem(
    title: 'RoadMap',
    description: 'System update schedule and future releases.',
    icon: Icons.route_outlined,
  ),
  const _FeatureItem(
    title: 'Gait Analysis',
    description: 'Stride metrics and symmetry tracking.',
    icon: Icons.device_hub_outlined,
  ),
  const _FeatureItem(
    title: 'BLE Status & Connection',
    description: 'Sensor and device health management.',
    icon: Icons.bluetooth_connected_outlined,
  ),
];

class _AppFeatureDirectoryView extends StatelessWidget {
  const _AppFeatureDirectoryView();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 80,
      ),
      itemCount: _features.length,
      itemBuilder: (context, index) {
        final feature = _features[index];
        final isCyan = index.isEven;
        final color = isCyan ? AppColors.primaryCyan : AppColors.secondaryPurple;
        final glow = isCyan ? AppColors.glowCyan : AppColors.glowPurple;
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: glow.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withOpacity(0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glow.withOpacity(0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Center(
                  child: _CustomFeatureIcon(
                    index: index,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      feature.title,
                      style: GoogleFonts.orbitron(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.description,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class _HubHero extends StatelessWidget {
  final bool compact;

  const _HubHero({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 18, vertical: compact ? 16 : 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A182B),
            Color(0xFF11243D),
            Color(0xFF0D1B2E),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x507E59F8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowCyan.withOpacity(0.08),
            blurRadius: 24,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _StarMeshPainter()),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Intelligence Hub',
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFFD6F7FF),
                        fontSize: compact ? 24 : 34,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: AppColors.glowCyan.withOpacity(0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-Assisted Guidance & Feature Overview',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFAFC7D8),
                        fontSize: compact ? 13 : 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const _AiBadge(),
                const SizedBox(width: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF213245),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Live system status',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGreen.withOpacity(0.45),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primaryCyan.withOpacity(0.28),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF13283A),
            border: Border.all(color: AppColors.primaryCyan.withOpacity(0.45), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryCyan.withOpacity(0.6),
                blurRadius: 16,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primaryCyan.withOpacity(0.5),
                size: 54,
              ),
              const Icon(
                Icons.headset_mic_outlined,
                color: AppColors.primaryCyan,
                size: 44,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'AI',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: AppColors.primaryCyan,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color borderColor;
  final IconData? titleIcon;

  const _HelpCard({
    required this.title,
    required this.child,
    this.borderColor = const Color(0x2A8AB8DB),
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(titleIcon, color: AppColors.primaryCyan, size: 18),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.orbitron(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SystemOverviewCard extends StatelessWidget {
  const _SystemOverviewCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'System Overview',
      borderColor: const Color(0x5F7A59F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 118,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: const [
                      Text('Insole visualization', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                      SizedBox(height: 6),
                      Expanded(child: _InsoleVisualTile()),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: const [
                      Expanded(child: _MedicalFigureTile()),
                      SizedBox(height: 6),
                      Text('AI medical illustration', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Parkinson’s assistance purpose, untitration, gait purposed, FOG monitoring, & adaptive cueing overview',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          const _FlowMiniDiagram(),
        ],
      ),
    );
  }
}

class _MonitoringGuideCard extends StatelessWidget {
  const _MonitoringGuideCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'Real-Time Monitoring Guide',
      borderColor: const Color(0x557E59F8),
      child: Column(
        children: [
          SizedBox(
            height: 92,
            child: Row(
              children: const [
                Expanded(child: _MiniPanelPreview()),
                SizedBox(width: 10),
                Expanded(child: _GuideMetricStack()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsExplanationCard extends StatelessWidget {
  const _AnalyticsExplanationCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'AI Analytics Explanation',
      child: Column(
        children: [
          SizedBox(
            height: 92,
            child: Row(
              children: const [
                Expanded(child: _MiniChartCard()),
                SizedBox(width: 10),
                Expanded(child: _NeuralGraphTile()),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI commentary example, neunaneneric exampe, neural-network visual accents',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _EmergencyFeaturesCard extends StatelessWidget {
  const _EmergencyFeaturesCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'Emergency & Safety Features',
      borderColor: const Color(0x77FF6B7B),
      child: Row(
        children: const [
          Expanded(child: _EmergencyVisualsTile()),
          SizedBox(width: 14),
          Expanded(child: _EmergencyExplainerTile()),
        ],
      ),
    );
  }
}

class _AdaptiveCueGuideCard extends StatelessWidget {
  const _AdaptiveCueGuideCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'Adaptive Cueing System',
      child: Column(
        children: [
          const SizedBox(
            height: 110,
            child: _CueModesVisual(),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(child: _CueLabelTile(title: 'Visual\n(laser)')),
              SizedBox(width: 8),
              Expanded(child: _CueLabelTile(title: 'Haptic\n(vibration)')),
              SizedBox(width: 8),
              Expanded(child: _CueLabelTile(title: 'Rhythmic Audio\n(tones)')),
            ],
          ),
        ],
      ),
    );
  }
}


class _FutureAiCard extends StatelessWidget {
  const _FutureAiCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'Future AI Features',
      child: Column(
        children: [
          const SizedBox(height: 92, child: _FutureAiVisual()),
          const SizedBox(height: 8),
          Text(
            'A visionary, next-generation roadmap - for predictive gait analysis, personalized therapy, caregiver cloud, adaptive ML, long-term tracking.',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _AssistantTipsCard extends StatelessWidget {
  const _AssistantTipsCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'AI Assistant Tips',
      titleIcon: Icons.smart_toy_outlined,
      borderColor: const Color(0x6A8AE7F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF213245),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              'Medical-tech assistant',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '- Stable gait detected.\n- Low BLE signal strength.\n- Cadence improving.\n- Battery optimization active.\n\n- Conver sx the bagemin tips.',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 12,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpMobilePlaceholder extends StatelessWidget {
  const _HelpMobilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        'System Intelligence Hub is optimized for the desktop sidebar experience.',
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      ),
    );
  }
}

class _InsoleVisualTile extends StatelessWidget {
  const _InsoleVisualTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF102337), Color(0xFF0C1727)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(painter: _InsoleTilePainter()),
    );
  }
}

class _MedicalFigureTile extends StatelessWidget {
  const _MedicalFigureTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF111F34), Color(0xFF0A1323)],
        ),
      ),
      child: CustomPaint(painter: _MedicalFigurePainter()),
    );
  }
}

class _FlowMiniDiagram extends StatelessWidget {
  const _FlowMiniDiagram();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: CustomPaint(painter: _FlowDiagramPainter()),
    );
  }
}

class _MiniPanelPreview extends StatelessWidget {
  const _MiniPanelPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162536),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: CustomPaint(painter: _MiniPanelPainter()),
    );
  }
}

class _GuideMetricStack extends StatelessWidget {
  const _GuideMetricStack();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Expanded(child: _MetricPill(label: 'Gait Stability', value: 'FOG', color: Color(0xFFFFCC4D))),
        SizedBox(height: 8),
        Expanded(child: _MetricPill(label: 'BLE Indicators', value: '9.3', color: AppColors.primaryCyan)),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162536),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChartCard extends StatelessWidget {
  const _MiniChartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162536),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(painter: _MiniChartPainter()),
    );
  }
}

class _NeuralGraphTile extends StatelessWidget {
  const _NeuralGraphTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162536),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(painter: _NeuralGraphPainter()),
    );
  }
}

class _EmergencyVisualsTile extends StatelessWidget {
  const _EmergencyVisualsTile();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: Row(
            children: const [
              Expanded(child: _WarningBubble(icon: Icons.warning_amber_rounded)),
              SizedBox(width: 10),
              Expanded(child: _WarningBubble(icon: Icons.notifications_active_outlined)),
              SizedBox(width: 10),
              Expanded(child: _SafetyWaveVisual()),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use red neon accents, alert card style.\nFuturistic safety visuals emergency comms.',
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 10, height: 1.35),
        ),
      ],
    );
  }
}

class _EmergencyExplainerTile extends StatelessWidget {
  const _EmergencyExplainerTile();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            Expanded(child: _TinyAlertCard(label: 'Fall detection')),
            SizedBox(width: 8),
            Expanded(child: _TinyAlertCard(label: 'SOS trigger')),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Futuristic safety visuals for Fall detection, SOS trigger, caregiver alerts, emergency comms.',
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, height: 1.35),
        ),
      ],
    );
  }
}

class _CueModesVisual extends StatelessWidget {
  const _CueModesVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Expanded(child: _CueWaveRow()),
        SizedBox(height: 8),
        Expanded(child: _CueIconsRow()),
      ],
    );
  }
}

class _CueWaveRow extends StatelessWidget {
  const _CueWaveRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _CuePreviewTile(icon: Icons.back_hand_outlined)),
        SizedBox(width: 8),
        Expanded(flex: 3, child: _CueWaveTile()),
      ],
    );
  }
}

class _CueIconsRow extends StatelessWidget {
  const _CueIconsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _CuePreviewTile(icon: Icons.linear_scale_rounded, accent: Color(0xFFFF4D73))),
        SizedBox(width: 8),
        Expanded(child: _CuePreviewTile(icon: Icons.sensors)),
        SizedBox(width: 8),
        Expanded(child: _CuePreviewTile(icon: Icons.graphic_eq_rounded, accent: Color(0xFFA66BFF))),
      ],
    );
  }
}

class _CuePreviewTile extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _CuePreviewTile({
    required this.icon,
    this.accent = AppColors.primaryCyan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162536),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Icon(icon, color: accent, size: 28),
    );
  }
}

class _CueWaveTile extends StatelessWidget {
  const _CueWaveTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162536),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: CustomPaint(painter: _CueWavePainter()),
    );
  }
}

class _CueLabelTile extends StatelessWidget {
  final String title;

  const _CueLabelTile({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 11,
        height: 1.2,
      ),
    );
  }
}

class _BleGuideCard extends StatelessWidget {
  const _BleGuideCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'BLE Connectivity Guide',
      child: Column(
        children: [
          const SizedBox(height: 92, child: _BleFlowVisual()),
          const SizedBox(height: 8),
          Text(
            'Explain pairing, device states, sync, battery. Explain pairing, device states, sync, battery.',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _BleFlowVisual extends StatelessWidget {
  const _BleFlowVisual();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BleFlowPainter());
  }
}

class _FutureAiVisual extends StatelessWidget {
  const _FutureAiVisual();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _FutureAiPainter());
  }
}

class _WarningBubble extends StatelessWidget {
  final IconData icon;

  const _WarningBubble({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF201E2F),
        border: Border.all(color: const Color(0x88FF6B7B)),
        boxShadow: [
          BoxShadow(color: const Color(0x44FF6B7B), blurRadius: 12),
        ],
      ),
      child: Icon(icon, color: const Color(0xFFFF6B7B)),
    );
  }
}

class _SafetyWaveVisual extends StatelessWidget {
  const _SafetyWaveVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162536),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(painter: _SafetyWavePainter()),
    );
  }
}

class _TinyAlertCard extends StatelessWidget {
  final String label;

  const _TinyAlertCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF251D2B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x88FF6B7B)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B7B), size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = const Color(0x66A7EEFF);
    final stars = [
      Offset(size.width * 0.62, size.height * 0.18),
      Offset(size.width * 0.70, size.height * 0.30),
      Offset(size.width * 0.78, size.height * 0.18),
      Offset(size.width * 0.86, size.height * 0.34),
      Offset(size.width * 0.74, size.height * 0.56),
      Offset(size.width * 0.67, size.height * 0.48),
    ];
    for (final star in stars) {
      canvas.drawCircle(star, 2.2, starPaint);
      canvas.drawCircle(
        star,
        8,
        Paint()
          ..color = const Color(0x22A7EEFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    final linePaint = Paint()
      ..color = const Color(0x2247B5FF)
      ..strokeWidth = 1;
    for (int i = 0; i < stars.length - 1; i++) {
      canvas.drawLine(stars[i], stars[i + 1], linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InsoleTilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.38, size.height * 0.54);
    final path = Path()
      ..moveTo(center.dx, size.height * 0.14)
      ..cubicTo(size.width * 0.72, size.height * 0.18, size.width * 0.74, size.height * 0.40, size.width * 0.58, size.height * 0.54)
      ..cubicTo(size.width * 0.46, size.height * 0.66, size.width * 0.48, size.height * 0.86, size.width * 0.30, size.height * 0.90)
      ..cubicTo(size.width * 0.14, size.height * 0.86, size.width * 0.10, size.height * 0.66, size.width * 0.18, size.height * 0.50)
      ..cubicTo(size.width * 0.24, size.height * 0.34, size.width * 0.18, size.height * 0.18, center.dx, size.height * 0.14)
      ..close();
    canvas.drawShadow(path, AppColors.primaryCyan, 10, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8DF5FF), Color(0xFF3C8FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'Insole\nvisualization',
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 60);
    labelPainter.paint(canvas, Offset(size.width * 0.72, size.height * 0.10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MedicalFigurePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF142942), Color(0xFF0E1727)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      bg,
    );
    final bodyPaint = Paint()
      ..color = const Color(0x66B8E7FF)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final cx = size.width * 0.50;
    final top = size.height * 0.14;
    canvas.drawCircle(Offset(cx, top + 10), 8, bodyPaint..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(cx, top + 20), Offset(cx, size.height * 0.56), bodyPaint);
    canvas.drawLine(Offset(cx, size.height * 0.26), Offset(size.width * 0.36, size.height * 0.40), bodyPaint);
    canvas.drawLine(Offset(cx, size.height * 0.26), Offset(size.width * 0.64, size.height * 0.40), bodyPaint);
    canvas.drawLine(Offset(cx, size.height * 0.56), Offset(size.width * 0.40, size.height * 0.84), bodyPaint);
    canvas.drawLine(Offset(cx, size.height * 0.56), Offset(size.width * 0.60, size.height * 0.84), bodyPaint);
    final chest = Rect.fromCenter(center: Offset(cx, size.height * 0.44), width: 18, height: 22);
    canvas.drawOval(
      chest,
      Paint()
        ..color = const Color(0x66FF4D73)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'AI medical illustration',
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width);
    labelPainter.paint(canvas, Offset(size.width * 0.08, size.height * 0.88));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlowDiagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final nodes = [
      Rect.fromLTWH(0, 18, 56, 28),
      Rect.fromLTWH(size.width * 0.36, 4, 68, 28),
      Rect.fromLTWH(size.width * 0.36, 36, 68, 28),
      Rect.fromLTWH(size.width - 58, 18, 56, 28),
    ];
    final labels = ['FOG\nmonitor', 'Neural\nanalysis', 'Cueing\nsystem', 'Caregiver\nalerts'];
    final paint = Paint()
      ..color = const Color(0x99253D56)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.35)
      ..style = PaintingStyle.stroke;
    final linePaint = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.28)
      ..strokeWidth = 1.2;
    for (int i = 0; i < nodes.length; i++) {
      final r = RRect.fromRectAndRadius(nodes[i], const Radius.circular(8));
      canvas.drawRRect(r, paint);
      canvas.drawRRect(r, border);
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 8)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: nodes[i].width);
      tp.paint(canvas, Offset(nodes[i].left, nodes[i].top + 5));
    }
    canvas.drawLine(nodes[0].centerRight, nodes[1].centerLeft, linePaint);
    canvas.drawLine(nodes[0].centerRight, nodes[2].centerLeft, linePaint);
    canvas.drawLine(nodes[1].centerRight, nodes[3].centerLeft, linePaint);
    canvas.drawLine(nodes[2].centerRight, nodes[3].centerLeft, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniPanelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cardPaint = Paint()..color = const Color(0xFF223548);
    for (int i = 0; i < 4; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(6 + (i % 2) * (size.width * 0.47), 8 + (i ~/ 2) * 34, size.width * 0.40, 24),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, cardPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFF213548);
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path()..moveTo(0, size.height * 0.70);
    for (double x = 0; x <= size.width; x++) {
      final t = x / size.width;
      final y = size.height * (0.62 - 0.18 * math.sin(t * 5 * math.pi) - 0.08 * math.sin(t * 12 * math.pi));
      path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(colors: [AppColors.primaryCyan, Color(0xFFA66BFF)]).createShader(Offset.zero & size)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NeuralGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pointsA = [
      Offset(size.width * 0.18, size.height * 0.25),
      Offset(size.width * 0.18, size.height * 0.50),
      Offset(size.width * 0.18, size.height * 0.75),
    ];
    final pointsB = [
      Offset(size.width * 0.52, size.height * 0.18),
      Offset(size.width * 0.52, size.height * 0.50),
      Offset(size.width * 0.52, size.height * 0.82),
    ];
    final pointsC = [
      Offset(size.width * 0.84, size.height * 0.28),
      Offset(size.width * 0.84, size.height * 0.70),
    ];
    final linePaint = Paint()
      ..color = const Color(0x668AE7F5)
      ..strokeWidth = 1.2;
    for (final a in pointsA) {
      for (final b in pointsB) {
        canvas.drawLine(a, b, linePaint);
      }
    }
    for (final b in pointsB) {
      for (final c in pointsC) {
        canvas.drawLine(b, c, linePaint);
      }
    }
    for (final p in [...pointsA, ...pointsB, ...pointsC]) {
      canvas.drawCircle(p, 4, Paint()..color = const Color(0xFFA66BFF));
      canvas.drawCircle(p, 10, Paint()..color = const Color(0x22A66BFF));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CueWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height / 2);
    for (double x = 0; x <= size.width; x++) {
      final t = x / size.width;
      final mix = Color.lerp(AppColors.primaryCyan, const Color(0xFFA66BFF), t)!;
      final y = size.height / 2 + math.sin(t * 8 * math.pi) * (size.height * 0.22);
      path.lineTo(x, y);
      canvas.drawCircle(Offset(x, y), 0.7, Paint()..color = mix);
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(colors: [AppColors.primaryCyan, Color(0xFFA66BFF)]).createShader(Offset.zero & size)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BleFlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x668AE7F5)
      ..strokeWidth = 1.4;
    final left = [Offset(20, 18), Offset(20, 46), Offset(20, 74)];
    final center = Offset(size.width / 2, size.height / 2);
    final right = [Offset(size.width - 26, 18), Offset(size.width - 26, 46), Offset(size.width - 26, 74)];
    for (final p in left) {
      canvas.drawLine(p, center, line);
    }
    for (final p in right) {
      canvas.drawLine(center, p, line);
    }
    canvas.drawCircle(center, 18, Paint()..color = const Color(0x2219D8FF));
    canvas.drawCircle(center, 16, Paint()..color = const Color(0xFF102E44));
    final tp = TextPainter(
      text: TextSpan(text: 'B', style: GoogleFonts.orbitron(color: AppColors.primaryCyan, fontSize: 18, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    for (final p in [...left, ...right]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 30, height: 18), const Radius.circular(6)),
        Paint()..color = const Color(0xFF213245),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FutureAiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.64;
    final path = Path()..moveTo(0, horizon);
    for (double x = 0; x <= size.width; x++) {
      final t = x / size.width;
      final y = horizon - math.sin(t * 3 * math.pi) * 12 - math.sin(t * 8 * math.pi) * 4;
      path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(colors: [AppColors.primaryCyan, Color(0xFFA66BFF)]).createShader(Offset.zero & size)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    for (final x in [0.12, 0.36, 0.58, 0.76, 0.90]) {
      final c = Offset(size.width * x, horizon - 10 - (x * 10));
      canvas.drawCircle(c, 8, Paint()..color = const Color(0x2219D8FF));
      canvas.drawCircle(c, 2.4, Paint()..color = const Color(0xFFA7EEFF));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SafetyWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [const Color(0xFFFF6B7B), AppColors.primaryCyan, const Color(0xFFFF6B7B)];
    for (int i = 0; i < 12; i++) {
      final x = size.width * (i + 1) / 13;
      final height = (i.isEven ? 0.62 : 0.34) * size.height;
      canvas.drawLine(
        Offset(x, size.height / 2 - height / 2),
        Offset(x, size.height / 2 + height / 2),
        Paint()
          ..color = colors[i % colors.length]
          ..strokeWidth = 2.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CustomFeatureIcon extends StatelessWidget {
  final int index;
  final Color color;

  const _CustomFeatureIcon({required this.index, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return CustomPaint(
          size: const Size(24, 24),
          painter: _LaserGuidePainter(color),
        );
      case 1:
        return CustomPaint(
          size: const Size(24, 24),
          painter: _FootPulsePainter(color),
        );
      case 2:
        return CustomPaint(
          size: const Size(24, 24),
          painter: _FootCuePainter(color),
        );
      case 3:
        return CustomPaint(
          size: const Size(24, 24),
          painter: _PulseWavePainter(color),
        );
      case 4:
        return CustomPaint(
          size: const Size(24, 24),
          painter: _WalkerPainter(color),
        );
      case 5:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: Text(
              'SOS',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.1,
              ),
            ),
          ),
        );
      case 6:
        return CustomPaint(
          size: const Size(24, 24),
          painter: _FootWarningPainter(color),
        );
      case 7:
        return CustomPaint(
          size: const Size(24, 24),
          painter: _LineGraphPainter(color),
        );
      case 8:
        return CustomPaint(
          size: const Size(24, 24),
          painter: _SineWavePainter(color),
        );
      case 9:
        return CustomPaint(
          size: const Size(24, 24),
          painter: _RoadmapPainter(color),
        );
      case 10:
        return CustomPaint(
          size: const Size(24, 24),
          painter: _DropletPinPainter(color),
        );
      case 11:
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 4,
              child: Icon(Icons.bluetooth, color: color, size: 14),
            ),
            Positioned(
              right: 4,
              child: Icon(Icons.smartphone_outlined, color: color, size: 14),
            ),
          ],
        );
      default:
        return Icon(Icons.help_outline, color: color, size: 22);
    }
  }
}

class _LaserGuidePainter extends CustomPainter {
  final Color color;
  _LaserGuidePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(Offset(size.width * 0.15, size.height * 0.85), Offset(size.width * 0.7, size.height * 0.3), paint);
    
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.3), 3.5, fillPaint);
    
    final haloPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.3), 6, haloPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulseWavePainter extends CustomPainter {
  final Color color;
  _PulseWavePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.lineTo(size.width * 0.25, size.height * 0.5);
    path.lineTo(size.width * 0.35, size.height * 0.25);
    path.lineTo(size.width * 0.45, size.height * 0.75);
    path.lineTo(size.width * 0.55, size.height * 0.15);
    path.lineTo(size.width * 0.65, size.height * 0.65);
    path.lineTo(size.width * 0.75, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.5);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SineWavePainter extends CustomPainter {
  final Color color;
  _SineWavePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final path = Path();
    path.moveTo(0, size.height * 0.5);
    for (double x = 0; x <= size.width; x += 1.0) {
      final y = size.height * 0.5 + 6 * math.sin((x / size.width) * 4 * math.pi);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoadmapPainter extends CustomPainter {
  final Color color;
  _RoadmapPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    
    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final nodeOutlinePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final p1 = Offset(size.width * 0.2, size.height * 0.7);
    final p2 = Offset(size.width * 0.5, size.height * 0.3);
    final p3 = Offset(size.width * 0.8, size.height * 0.6);

    final path = Path();
    path.moveTo(p1.dx, p1.dy);
    path.quadraticBezierTo(size.width * 0.35, size.height * 0.4, p2.dx, p2.dy);
    path.quadraticBezierTo(size.width * 0.65, size.height * 0.5, p3.dx, p3.dy);
    canvas.drawPath(path, linePaint);

    canvas.drawCircle(p1, 3, nodePaint);
    canvas.drawCircle(p1, 5.5, nodeOutlinePaint);
    canvas.drawCircle(p2, 3, nodePaint);
    canvas.drawCircle(p2, 5.5, nodeOutlinePaint);
    canvas.drawCircle(p3, 3, nodePaint);
    canvas.drawCircle(p3, 5.5, nodeOutlinePaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LineGraphPainter extends CustomPainter {
  final Color color;
  _LineGraphPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final pts = [
      Offset(size.width * 0.15, size.height * 0.75),
      Offset(size.width * 0.4, size.height * 0.45),
      Offset(size.width * 0.65, size.height * 0.65),
      Offset(size.width * 0.85, size.height * 0.3),
    ];

    final path = Path();
    path.moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, linePaint);

    for (final pt in pts) {
      canvas.drawCircle(pt, 2.5, nodePaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FootPulsePainter extends CustomPainter {
  final Color color;
  _FootPulsePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    final footPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final path = Path();
    final xOff = -w * 0.08;
    path.moveTo(w * 0.4 + xOff, h * 0.8);
    path.cubicTo(w * 0.28 + xOff, h * 0.8, w * 0.28 + xOff, h * 0.7, w * 0.33 + xOff, h * 0.6);
    path.cubicTo(w * 0.38 + xOff, h * 0.52, w * 0.38 + xOff, h * 0.45, w * 0.3 + xOff, h * 0.35);
    path.cubicTo(w * 0.25 + xOff, h * 0.28, w * 0.33 + xOff, h * 0.2, w * 0.42 + xOff, h * 0.2);
    path.cubicTo(w * 0.52 + xOff, h * 0.2, w * 0.57 + xOff, h * 0.28, w * 0.53 + xOff, h * 0.38);
    path.cubicTo(w * 0.48 + xOff, h * 0.5, w * 0.52 + xOff, h * 0.68, w * 0.4 + xOff, h * 0.8);
    path.close();
    canvas.drawPath(path, footPaint);
    
    final wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
      
    canvas.drawArc(Rect.fromLTWH(w * 0.42, h * 0.3, w * 0.25, h * 0.4), -math.pi / 4, math.pi / 2, false, wavePaint);
    canvas.drawArc(Rect.fromLTWH(w * 0.52, h * 0.24, w * 0.28, h * 0.52), -math.pi / 4, math.pi / 2, false, wavePaint);
    canvas.drawArc(Rect.fromLTWH(w * 0.62, h * 0.18, w * 0.32, h * 0.64), -math.pi / 4, math.pi / 2, false, wavePaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FootCuePainter extends CustomPainter {
  final Color color;
  _FootCuePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    final footPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    final path = Path();
    path.moveTo(w * 0.5, h * 0.8);
    path.cubicTo(w * 0.38, h * 0.8, w * 0.38, h * 0.7, w * 0.43, h * 0.6);
    path.cubicTo(w * 0.48, h * 0.52, w * 0.48, h * 0.45, w * 0.4, h * 0.35);
    path.cubicTo(w * 0.35, h * 0.28, w * 0.43, h * 0.2, w * 0.52, h * 0.2);
    path.cubicTo(w * 0.62, h * 0.2, w * 0.67, h * 0.28, w * 0.63, h * 0.38);
    path.cubicTo(w * 0.58, h * 0.5, w * 0.62, h * 0.68, w * 0.5, h * 0.8);
    path.close();
    canvas.drawPath(path, footPaint);
    
    final cuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
      
    canvas.drawArc(Rect.fromLTWH(w * 0.4, h * 0.05, w * 0.24, h * 0.2), math.pi, math.pi, false, cuePaint);
    canvas.drawArc(Rect.fromLTWH(w * 0.35, h * -0.01, w * 0.34, h * 0.24), math.pi, math.pi, false, cuePaint);
    
    canvas.drawArc(Rect.fromLTWH(w * 0.4, h * 0.75, w * 0.24, h * 0.2), 0, math.pi, false, cuePaint);
    canvas.drawArc(Rect.fromLTWH(w * 0.35, h * 0.77, w * 0.34, h * 0.24), 0, math.pi, false, cuePaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WalkerPainter extends CustomPainter {
  final Color color;
  _WalkerPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    canvas.drawCircle(Offset(w * 0.5, h * 0.22), 3, Paint()..color = color..style = PaintingStyle.fill);
    
    canvas.drawLine(Offset(w * 0.5, h * 0.28), Offset(w * 0.5, h * 0.55), paint);
    
    canvas.drawLine(Offset(w * 0.5, h * 0.33), Offset(w * 0.32, h * 0.48), paint);
    canvas.drawLine(Offset(w * 0.5, h * 0.33), Offset(w * 0.65, h * 0.42), paint);
    
    final legPath1 = Path()
      ..moveTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.38, h * 0.72)
      ..lineTo(w * 0.32, h * 0.85);
    canvas.drawPath(legPath1, paint);
    
    final legPath2 = Path()
      ..moveTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.6, h * 0.7)
      ..lineTo(w * 0.64, h * 0.85);
    canvas.drawPath(legPath2, paint);
    
    final refPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w * 0.2, h * 0.86), Offset(w * 0.8, h * 0.86), refPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FootWarningPainter extends CustomPainter {
  final Color color;
  _FootWarningPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    final footPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    final path = Path();
    path.moveTo(w * 0.5, h * 0.8);
    path.cubicTo(w * 0.38, h * 0.8, w * 0.38, h * 0.7, w * 0.43, h * 0.6);
    path.cubicTo(w * 0.48, h * 0.52, w * 0.48, h * 0.45, w * 0.4, h * 0.35);
    path.cubicTo(w * 0.35, h * 0.28, w * 0.43, h * 0.2, w * 0.52, h * 0.2);
    path.cubicTo(w * 0.62, h * 0.2, w * 0.67, h * 0.28, w * 0.63, h * 0.38);
    path.cubicTo(w * 0.58, h * 0.5, w * 0.62, h * 0.68, w * 0.5, h * 0.8);
    path.close();
    canvas.drawPath(path, footPaint);
    
    final alertPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
      
    final triPath = Path()
      ..moveTo(w * 0.68, h * 0.25)
      ..lineTo(w * 0.56, h * 0.45)
      ..lineTo(w * 0.8, h * 0.45)
      ..close();
    canvas.drawPath(triPath, alertPaint);
    
    final fillPaint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.67, h * 0.32, 1.5, 5), fillPaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.41), 1, fillPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DropletPinPainter extends CustomPainter {
  final Color color;
  _DropletPinPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
      
    final dropPath = Path()
      ..moveTo(w * 0.35, h * 0.2)
      ..cubicTo(w * 0.35, h * 0.2, w * 0.15, h * 0.5, w * 0.15, h * 0.65)
      ..arcToPoint(Offset(w * 0.55, h * 0.65), radius: Radius.circular(w * 0.2), largeArc: true)
      ..cubicTo(w * 0.55, h * 0.5, w * 0.35, h * 0.2, w * 0.35, h * 0.2)
      ..close();
    canvas.drawPath(dropPath, paint);
    
    final pinPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final pinPath = Path()
      ..moveTo(w * 0.7, h * 0.4)
      ..cubicTo(w * 0.58, h * 0.4, w * 0.55, h * 0.55, w * 0.7, h * 0.75)
      ..cubicTo(w * 0.85, h * 0.55, w * 0.82, h * 0.4, w * 0.7, h * 0.4)
      ..close();
    canvas.drawPath(pinPath, pinPaint);
    canvas.drawCircle(Offset(w * 0.7, h * 0.48), 2, Paint()..color = color..style = PaintingStyle.fill);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
