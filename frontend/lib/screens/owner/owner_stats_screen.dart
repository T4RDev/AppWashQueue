import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class OwnerStatsScreen extends StatefulWidget {
  const OwnerStatsScreen({super.key});

  @override
  State<OwnerStatsScreen> createState() => _OwnerStatsScreenState();
}

class _OwnerStatsScreenState extends State<OwnerStatsScreen> {
  String _period = 'month'; // 'day', 'month', 'year'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'สถิติร้าน',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Segment Tabs (Matches 3.5_Owner_Stats.png)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF5),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildPeriodTab('day', 'รายวัน'),
                  _buildPeriodTab('month', 'รายเดือน'),
                  _buildPeriodTab('year', 'รายปี'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Revenue & Weekly Bar Chart Card (Matches 3.5_Owner_Stats.png)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'รายได้ ตุลาคม 2569',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6FFED),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '▲ 12% จากเดือนก่อน',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF389E0D),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '฿48,600',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Simple Bar Chart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBarCol(
                        '9.8k',
                        0.55,
                        'สัปดาห์ 1',
                        isHighlight: false,
                      ),
                      _buildBarCol(
                        '12.4k',
                        0.72,
                        'สัปดาห์ 2',
                        isHighlight: false,
                      ),
                      _buildBarCol(
                        '11.2k',
                        0.65,
                        'สัปดาห์ 3',
                        isHighlight: false,
                      ),
                      _buildBarCol(
                        '15.2k',
                        0.95,
                        'สัปดาห์ 4',
                        isHighlight: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3 Stat Boxes (Matches 3.5_Owner_Stats.png)
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'ผู้ใช้บริการ',
                    '312 คัน',
                    AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatItem(
                    'ไม่มาตามนัด',
                    '6 ครั้ง',
                    Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatItem(
                    'คะแนนเฉลี่ย',
                    '4.8 ★',
                    const Color(0xFFD48806),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Popular Time Slots Card (Matches 3.5_Owner_Stats.png)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ช่วงเวลาที่มีผู้ใช้บริการมาก',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimeBar('08:00–10:00', 0.92, '92', isTop: true),
                  _buildTimeBar('10:00–12:00', 0.74, '74', isTop: false),
                  _buildTimeBar('13:00–15:00', 0.58, '58', isTop: false),
                  _buildTimeBar('15:00–17:00', 0.88, '88', isTop: true),
                  const SizedBox(height: 8),
                  const Text(
                    'วันที่มีผู้ใช้บริการมากที่สุด: เสาร์ และ ศุกร์',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String key, String label) {
    final isSelected = _period == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarCol(
    String valText,
    double heightRatio,
    String label, {
    required bool isHighlight,
  }) {
    return Column(
      children: [
        Text(
          valText,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 52,
          height: 140 * heightRatio,
          decoration: BoxDecoration(
            color: isHighlight ? null : const Color(0xFFD6E4FF),
            gradient: isHighlight
                ? const LinearGradient(
                    colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String val, Color valColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBar(
    String time,
    double ratio,
    String count, {
    required bool isTop,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 12,
                backgroundColor: const Color(0xFFF0F4FA),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isTop ? AppTheme.primaryColor : const Color(0xFF85A5FF),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 24,
            child: Text(
              count,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
