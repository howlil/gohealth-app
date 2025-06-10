import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/navigations/app_layout.dart';
import '../utils/app_colors.dart';
import '../widgets/inputs/rounded_input_field.dart';
import '../widgets/glass_card.dart';
import '../widgets/inputs/tab_selector.dart';
import 'ibm/models/ibm_history.dart';

class IBMScreen extends StatefulWidget {
  const IBMScreen({super.key});

  @override
  State<IBMScreen> createState() => _IBMScreenState();
}

class _IBMScreenState extends State<IBMScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _heightController = TextEditingController(text: '170');
  final TextEditingController _weightController = TextEditingController(text: '55');
  
  double _bmi = 0.0;
  String _category = '';
  Color _categoryColor = Colors.transparent;
  bool _hasCalculated = false;
  
  late TabController _tabController;
  String _activeTab = 'Ringkasan Gizi';

  // Dummy data untuk riwayat BMI
  final List<IBMHistory> _bmiHistory = [
    IBMHistory(
      date: DateTime(2025, 3, 19, 13, 09),
      bmi: 19.0,
      height: 170,
      weight: 55,
      category: 'Normal',
    ),
    IBMHistory(
      date: DateTime(2025, 3, 15, 10, 22),
      bmi: 19.5,
      height: 170,
      weight: 56.5,
      category: 'Normal',
    ),
    IBMHistory(
      date: DateTime(2025, 3, 10, 8, 15),
      bmi: 20.1,
      height: 170,
      weight: 58,
      category: 'Normal',
    ),
    IBMHistory(
      date: DateTime(2025, 3, 5, 19, 30),
      bmi: 20.8,
      height: 170,
      weight: 60,
      category: 'Normal',
    ),
  ];
  
  List<FlSpot> get _bmiSpots {
    return _bmiHistory.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final record = entry.value;
      return FlSpot(index, record.bmi);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _calculateBMI() {
    final height = double.tryParse(_heightController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    
    if (height <= 0 || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon masukkan tinggi dan berat yang valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Calculate BMI: weight / (height in meters)²
    final heightInMeters = height / 100;
    final bmi = weight / (heightInMeters * heightInMeters);
    
    String category;
    Color color;
    
    if (bmi < 18.5) {
      category = 'Kurus';
      color = Colors.blue;
    } else if (bmi < 25) {
      category = 'Normal';
      color = Colors.green;
    } else if (bmi < 30) {
      category = 'Berlebih';
      color = Colors.orange;
    } else {
      category = 'Obesitas';
      color = Colors.red;
    }
    
    setState(() {
      _bmi = bmi;
      _category = category;
      _categoryColor = color;
      _hasCalculated = true;
      
      // Add to history
      _bmiHistory.insert(
        0,
        IBMHistory(
          date: DateTime.now(),
          bmi: bmi,
          height: height,
          weight: weight,
          category: category,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Kalkulator & Pelacak BMI',
      backgroundColor: const Color(0xFFF8F9FA),
      showBackButton: true,
      child: Stack(
        children: [
          // Background gradients
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(13), // Fixed: withOpacity to withAlpha
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withAlpha(13), // Fixed: withOpacity to withAlpha
              ),
            ),
          ),
          
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildCalculatorSection(),
                const SizedBox(height: 24),
                _buildTabControl(),
                const SizedBox(height: 16),
                _activeTab == 'Ringkasan Gizi' 
                    ? _buildNutritionSummary() 
                    : _buildBMIHistory(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hitung BMI Anda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'BMI (Body Mass Index) adalah pengukuran yang menggunakan tinggi dan berat badan untuk memperkirakan jumlah lemak tubuh.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Tinggi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          RoundedInputField( // Fixed: Changed CustomInputField to InputField
            controller: _heightController,
            hintText: 'Masukkan tinggi (cm)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Berat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          RoundedInputField( // Fixed: Changed CustomInputField to InputField
            controller: _weightController,
            hintText: 'Masukkan berat (kg)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          
          // Calculate button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculateBMI,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text(
                'Hitung',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          if (_hasCalculated) ...[
            const SizedBox(height: 24),
            _buildBMIResult(),
          ],
        ],
      ),
    );
  }

  Widget _buildBMIResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _categoryColor.withAlpha(26), // Fixed: withOpacity(0.1) to withAlpha(26)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _categoryColor.withAlpha(77), // Fixed: withOpacity(0.3) to withAlpha(77)
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _categoryColor.withAlpha(51), // Fixed: withOpacity(0.2) to withAlpha(51)
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _bmi.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _categoryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _category,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _categoryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getBMIMessage(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getBMIMessage() {
    if (_category == 'Kurus') {
      return 'BMI Anda di bawah rentang normal. Pertimbangkan untuk berkonsultasi dengan ahli gizi.';
    } else if (_category == 'Normal') {
      return 'BMI Anda berada dalam rentang normal. Pertahankan pola hidup sehat Anda!';
    } else if (_category == 'Berlebih') {
      return 'BMI Anda sedikit di atas rentang normal. Pertimbangkan untuk lebih aktif bergerak.';
    } else {
      return 'BMI Anda jauh di atas rentang normal. Konsultasikan dengan profesional kesehatan.';
    }
  }

  Widget _buildTabControl() {
    return TabSelector(
      tabs: const ['Ringkasan Gizi', 'Riwayat BMI'],
      selectedTab: _activeTab,
      onTabSelected: (tab) {
        setState(() {
          _activeTab = tab;
        });
      },
    );
  }

  Widget _buildNutritionSummary() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Gizi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildNutritionItem(
            title: 'Kebutuhan Kalori Harian',
            value: '1800-2200 kkal',
            description: 'Berdasarkan BMI, umur, dan tingkat aktivitas',
            icon: Icons.local_fire_department_outlined,
            color: AppColors.accent1,
          ),
          const SizedBox(height: 16),
          _buildNutritionItem(
            title: 'Protein',
            value: '55-75 gram',
            description: '15-20% dari total kalori harian',
            icon: Icons.egg_outlined,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          _buildNutritionItem(
            title: 'Karbohidrat',
            value: '225-325 gram',
            description: '50-60% dari total kalori harian',
            icon: Icons.rice_bowl_outlined,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _buildNutritionItem(
            title: 'Lemak',
            value: '40-70 gram',
            description: '20-30% dari total kalori harian',
            icon: Icons.opacity,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(26), // Fixed: withOpacity(0.1) to withAlpha(26)
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBMIHistory() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat BMI',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pelacakan perubahan BMI Anda dari waktu ke waktu',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          
          // Graph/List toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton('Grafik', 0),
                _buildToggleButton('Daftar', 1),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Tab content
          IndexedStack(
            index: _tabController.index,
            children: [
              _buildBMIGraph(),
              _buildBMIList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, int index) {
    final isSelected = _tabController.index == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.index = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildBMIGraph() {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 5,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value >= _bmiHistory.length || value < 0) {
                    return const SizedBox.shrink();
                  }
                  
                  final date = _bmiHistory[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  );
                },
                interval: 5,
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: _bmiHistory.length.toDouble() - 1,
          minY: 15,
          maxY: 35,
          lineBarsData: [
            LineChartBarData(
              spots: _bmiSpots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withAlpha(26), // Fixed: withOpacity(0.1) to withAlpha(26)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMIList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _bmiHistory.length,
      separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final record = _bmiHistory[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(
                '${record.date.day} ${_getMonthName(record.date.month)} ${record.date.year}, ${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        'BMI: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        record.bmi.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Tinggi: ${record.height} cm',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Berat: ${record.weight} kg',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }
}