import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/navigations/app_layout.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';
import '../widgets/inputs/rounded_input_field.dart';
import '../widgets/glass_card.dart';
import '../widgets/inputs/tab_selector.dart';
import '../models/ibm_history.dart';
import '../services/bmi_service.dart';
import '../widgets/bmi/weight_goal_card.dart';
import '../widgets/loading_skeleton.dart';

class IBMScreen extends StatefulWidget {
  const IBMScreen({super.key});

  @override
  State<IBMScreen> createState() => _IBMScreenState();
}

class _IBMScreenState extends State<IBMScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  double _bmi = 0.0;
  String _category = '';
  Color _categoryColor = Colors.transparent;
  bool _hasCalculated = false;
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  bool _hasMoreData = true;
  String? _errorMessage;

  late TabController _tabController;
  String _activeTab = 'Ringkasan Gizi';

  final BMIService _bmiService = BMIService();
  List<IBMHistory> _bmiHistory = [];
  int _currentPage = 1;
  static const int _pageSize = 10;

  // Nutrition summary data
  Map<String, dynamic>? _nutritionSummary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBMIHistory();
  }

  Future<void> _loadBMIHistory({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _bmiHistory = [];
      });
    }

    if (!_hasMoreData || _isLoadingHistory) return;

    setState(() {
      _isLoadingHistory = true;
      _errorMessage = null;
    });

    try {
      final response = await _bmiService.getBMIHistory(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (!mounted) return;

      if (response != null && response.success && response.data != null) {
        final newRecords = response.data!;
        setState(() {
          if (refresh) {
            _bmiHistory = newRecords;
          } else {
            _bmiHistory.addAll(newRecords);
          }
          _hasMoreData = newRecords.length == _pageSize;
          _currentPage++;
        });
      } else {
        setState(() {
          _errorMessage = response?.message ?? 'Gagal memuat riwayat BMI';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _refreshBMIHistory() async {
    await _loadBMIHistory(refresh: true);
  }

  List<FlSpot> get _bmiSpots {
    return _bmiHistory.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final record = entry.value;
      return FlSpot(index, record.bmi);
    }).toList();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _calculateBMI() async {
    // Validasi input tidak kosong
    if (_heightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon masukkan tinggi badan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon masukkan berat badan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (height == null || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tinggi badan harus berupa angka yang valid (cm)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berat badan harus berupa angka yang valid (kg)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _bmiService.calculateBMI(
        height: height,
        weight: weight,
      );

      if (!mounted) return;

      if (response != null && response.success && response.data != null) {
        final bmiRecord = response.data!;
        String category;
        Color color;

        switch (bmiRecord.status.toUpperCase()) {
          case 'UNDERWEIGHT':
            category = 'Kurus';
            color = Colors.blue;
            break;
          case 'NORMAL':
            category = 'Normal';
            color = Colors.green;
            break;
          case 'OVERWEIGHT':
            category = 'Berlebih';
            color = Colors.orange;
            break;
          case 'OBESE':
            category = 'Obesitas';
            color = Colors.red;
            break;
          default:
            category = 'Tidak diketahui';
            color = Colors.grey;
        }

        setState(() {
          _bmi = bmiRecord.bmi;
          _category = category;
          _categoryColor = color;
          _hasCalculated = true;
          _nutritionSummary = bmiRecord.nutritionSummary;

          // Switch to nutrition summary tab if calculation is successful and nutrition data is available
          if (_nutritionSummary != null) {
            _activeTab = 'Ringkasan Gizi';
          }
        });

        // Reload BMI history after successful calculation
        await _loadBMIHistory();
      } else {
        setState(() {
          _errorMessage = response?.message ?? 'Gagal menghitung BMI';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Gagal menghitung BMI'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

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
                color: AppColors.primary.withAlpha(13),
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
                color: AppColors.secondary.withAlpha(13),
              ),
            ),
          ),

          // Main content - responsive layout
          if (isMobileLandscape)
            _buildLandscapeLayout()
          else
            _buildPortraitLayout(),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: const Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: LoadingSkeleton(
                    width: 60,
                    height: 60,
                    borderRadius: 30,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Calculator section - ikut scroll
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildCalculatorSection(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Tab control - ikut scroll
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildTabControl(),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Content area - ikut dalam scroll yang sama
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (_activeTab == 'Ringkasan Gizi')
                  _buildNutritionSummary()
                else if (_activeTab == 'Target Berat')
                  _buildWeightGoalSection()
                else
                  _buildBMIHistory(),
                const SizedBox(height: 100), // Extra space for bottom nav
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Calculator
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildCalculatorSection(isLandscape: true),
              ),
            ),
            // Divider
            Container(
              width: 1,
              color: Colors.grey.shade200,
            ),
            // Right side - Results & Tabs
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Tab control
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _buildTabControl(),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (_activeTab == 'Ringkasan Gizi')
                            _buildNutritionSummary(isLandscape: true)
                          else if (_activeTab == 'Target Berat')
                            _buildWeightGoalSection()
                          else
                            _buildBMIHistory(isLandscape: true),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorSection({bool isLandscape = false}) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    return GlassCard(
      padding: EdgeInsets.all(isMobileLandscape ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hitung BMI Anda',
            style: TextStyle(
              fontSize: isMobileLandscape ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'BMI (Body Mass Index) adalah pengukuran yang menggunakan tinggi dan berat badan untuk memperkirakan jumlah lemak tubuh.',
            style: TextStyle(
              fontSize: isMobileLandscape ? 11 : 13,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          SizedBox(height: isMobileLandscape ? 16 : 24),

          Text(
            'Tinggi',
            style: TextStyle(
              fontSize: isMobileLandscape ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          RoundedInputField(
            controller: _heightController,
            hintText: 'Masukkan tinggi (cm)',
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: isMobileLandscape ? 12 : 16),

          Text(
            'Berat',
            style: TextStyle(
              fontSize: isMobileLandscape ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          RoundedInputField(
            controller: _weightController,
            hintText: 'Masukkan berat (kg)',
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: isMobileLandscape ? 16 : 24),

          // Calculate button
          SizedBox(
            width: double.infinity,
            height: isMobileLandscape ? 40 : 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _calculateBMI,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: isMobileLandscape ? 16 : 20,
                      height: isMobileLandscape ? 16 : 20,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Hitung',
                      style: TextStyle(
                        fontSize: isMobileLandscape ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          if (_hasCalculated) ...[
            SizedBox(height: isMobileLandscape ? 16 : 24),
            _buildBMIResult(isLandscape: isLandscape),
          ],
        ],
      ),
    );
  }

  Widget _buildBMIResult({bool isLandscape = false}) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isMobileLandscape = isMobile && isLandscape;

    return Container(
      padding: EdgeInsets.all(isMobileLandscape ? 12 : 16),
      decoration: BoxDecoration(
        color: _categoryColor.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _categoryColor.withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isMobileLandscape ? 48 : 60,
            height: isMobileLandscape ? 48 : 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _categoryColor.withAlpha(51),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _bmi.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: isMobileLandscape ? 16 : 18,
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
                    fontSize: isMobileLandscape ? 14 : 18,
                    fontWeight: FontWeight.bold,
                    color: _categoryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabControl() {
    return TabSelector(
      tabs: const ['Ringkasan Gizi', 'Target Berat', 'Riwayat BMI'],
      selectedIndex: _activeTab == 'Ringkasan Gizi'
          ? 0
          : (_activeTab == 'Target Berat' ? 1 : 2),
      onTabSelected: (index) {
        setState(() {
          _activeTab = index == 0
              ? 'Ringkasan Gizi'
              : (index == 1 ? 'Target Berat' : 'Riwayat BMI');
        });
      },
    );
  }

  Widget _buildNutritionSummary({bool isLandscape = false}) {
    if (_nutritionSummary == null) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Icon(
              Icons.restaurant_menu,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ringkasan Gizi Belum Tersedia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan hitung BMI Anda terlebih dahulu untuk melihat rekomendasi kebutuhan gizi harian',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    try {
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
            const SizedBox(height: 8),
            Text(
              'Rekomendasi kebutuhan gizi harian berdasarkan BMI Anda',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildNutritionItem(
              title: 'Kebutuhan Kalori Harian',
              value:
                  '${_nutritionSummary!['calories']['min']}-${_nutritionSummary!['calories']['max']} kkal',
              description: 'Berdasarkan BMI, tinggi badan, dan berat badan',
              icon: Icons.local_fire_department_outlined,
              color: AppColors.accent1,
            ),
            const SizedBox(height: 16),
            _buildNutritionItem(
              title: 'Protein',
              value:
                  '${_nutritionSummary!['protein']['min']}-${_nutritionSummary!['protein']['max']} ${_nutritionSummary!['protein']['unit']}',
              description: '15-20% dari total kalori harian',
              icon: Icons.egg_outlined,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 16),
            _buildNutritionItem(
              title: 'Karbohidrat',
              value:
                  '${_nutritionSummary!['carbohydrate']['min']}-${_nutritionSummary!['carbohydrate']['max']} ${_nutritionSummary!['carbohydrate']['unit']}',
              description: '50-60% dari total kalori harian',
              icon: Icons.rice_bowl_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            _buildNutritionItem(
              title: 'Lemak',
              value:
                  '${_nutritionSummary!['fat']['min']}-${_nutritionSummary!['fat']['max']} ${_nutritionSummary!['fat']['unit']}',
              description: '20-30% dari total kalori harian',
              icon: Icons.opacity,
              color: Colors.orange,
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error rendering nutrition summary: $e');
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Ringkasan Gizi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Terjadi kesalahan saat memuat data ringkasan gizi. Silakan coba hitung BMI kembali.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculateBMI,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hitung Ulang'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }
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
            color:
                color.withAlpha(26), // Fixed: withOpacity(0.1) to withAlpha(26)
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

  Widget _buildBMIHistory({bool isLandscape = false}) {
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
          if (_isLoadingHistory)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: BMIHistorySkeleton(itemCount: 3),
            )
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (_bmiHistory.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Belum ada riwayat BMI'),
              ),
            )
          else ...[
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
            SizedBox(
              height: 300, // Fixed height for the content
              child: IndexedStack(
                index: _tabController.index,
                children: [
                  _buildBMIGraph(),
                  _buildBMIList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBMIGraph() {
    if (_bmiHistory.isEmpty) {
      return const Center(
        child: Text('Tidak ada data untuk ditampilkan'),
      );
    }

    return Column(
      children: [
        // Data summary
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                title: 'Rata-rata BMI',
                value: _bmiHistory.isEmpty
                    ? '0'
                    : (_bmiHistory.map((e) => e.bmi).reduce((a, b) => a + b) /
                            _bmiHistory.length)
                        .toStringAsFixed(1),
              ),
              _buildStatItem(
                title: 'BMI Tertinggi',
                value: _bmiHistory.isEmpty
                    ? '0'
                    : _bmiHistory
                        .map((e) => e.bmi)
                        .reduce((a, b) => a > b ? a : b)
                        .toStringAsFixed(1),
              ),
              _buildStatItem(
                title: 'BMI Terendah',
                value: _bmiHistory.isEmpty
                    ? '0'
                    : _bmiHistory
                        .map((e) => e.bmi)
                        .reduce((a, b) => a < b ? a : b)
                        .toStringAsFixed(1),
              ),
            ],
          ),
        ),

        // Chart
        Expanded(
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

                      final date = _bmiHistory[value.toInt()].recordedAt;
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
                    interval: _bmiHistory.length > 10
                        ? (_bmiHistory.length / 5).ceilToDouble()
                        : 1,
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
              maxX: (_bmiHistory.length - 1).toDouble(),
              minY: 15,
              maxY: 35,
              lineTouchData: LineTouchData(
                enabled: true,
                touchCallback:
                    (FlTouchEvent event, LineTouchResponse? touchResponse) {
                  if (event is FlTapUpEvent &&
                      touchResponse?.lineBarSpots != null &&
                      touchResponse!.lineBarSpots!.isNotEmpty) {
                    final spotIndex =
                        touchResponse.lineBarSpots!.first.x.toInt();
                    if (spotIndex >= 0 && spotIndex < _bmiHistory.length) {
                      _showEditDeleteOptions(_bmiHistory[spotIndex]);
                    }
                  }
                },
                handleBuiltInTouches: true,
              ),
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
                    color: AppColors.primary.withAlpha(26),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBMIList() {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshBMIHistory,
            child: _bmiHistory.isEmpty
                ? const Center(
                    child: Text('Tidak ada data untuk periode yang dipilih'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _bmiHistory.length + (_hasMoreData ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        Divider(color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      if (index == _bmiHistory.length) {
                        if (_hasMoreData) {
                          _loadBMIHistory();
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: BMIHistorySkeleton(itemCount: 1),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final record = _bmiHistory[index];
                      return InkWell(
                        onTap: () {
                          // When tapped, update the UI with this record's data
                          setState(() {
                            _heightController.text = record.height.toString();
                            _weightController.text = record.weight.toString();
                            _bmi = record.bmi;
                            _category = _getBMICategoryText(record.status);
                            _categoryColor =
                                _getBMICategoryColor(record.status);
                            _hasCalculated = true;
                            _nutritionSummary = record.nutritionSummary;

                            // Switch to nutrition summary tab if available
                            if (_nutritionSummary != null) {
                              _activeTab = 'Ringkasan Gizi';
                              _tabController.index = 0;
                            }
                          });

                          // Scroll to top to show the BMI result
                          Scrollable.ensureVisible(
                            context,
                            duration: const Duration(milliseconds: 300),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${record.recordedAt.day} ${_getMonthName(record.recordedAt.month)} ${record.recordedAt.year}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
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
                              ),
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
                                  _buildBMIStatusBadge(record.status),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showEditDeleteOptions(record),
                                color: Colors.grey.shade600,
                                iconSize: 20,
                                splashRadius: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // Helper method to build BMI status badge
  Widget _buildBMIStatusBadge(String status) {
    Color color;
    String text;

    switch (status.toUpperCase()) {
      case 'UNDERWEIGHT':
        text = 'Kurus';
        color = Colors.blue;
        break;
      case 'NORMAL':
        text = 'Normal';
        color = Colors.green;
        break;
      case 'OVERWEIGHT':
        text = 'Berlebih';
        color = Colors.orange;
        break;
      case 'OBESE':
        text = 'Obesitas';
        color = Colors.red;
        break;
      default:
        text = status;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  // Helper method to get BMI category text
  String _getBMICategoryText(String status) {
    switch (status.toUpperCase()) {
      case 'UNDERWEIGHT':
        return 'Kurus';
      case 'NORMAL':
        return 'Normal';
      case 'OVERWEIGHT':
        return 'Berlebih';
      case 'OBESE':
        return 'Obesitas';
      default:
        return status;
    }
  }

  // Helper method to get BMI category color
  Color _getBMICategoryColor(String status) {
    switch (status.toUpperCase()) {
      case 'UNDERWEIGHT':
        return Colors.blue;
      case 'NORMAL':
        return Colors.green;
      case 'OVERWEIGHT':
        return Colors.orange;
      case 'OBESE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return months[month - 1];
  }

  // Show edit/delete options for a BMI record
  Future<void> _showEditDeleteOptions(IBMHistory record) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Opsi BMI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Edit Data BMI'),
              onTap: () {
                Navigator.pop(context);
                _showEditBMIDialog(record);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus Data BMI'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(record);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calculate, color: AppColors.secondary),
              title: const Text('Gunakan untuk Hitung Ulang'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _heightController.text = record.height.toString();
                  _weightController.text = record.weight.toString();
                  _activeTab = 'Ringkasan Gizi';
                });
                _calculateBMI();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show dialog to edit BMI record
  Future<void> _showEditBMIDialog(IBMHistory record) {
    final heightController =
        TextEditingController(text: record.height.toString());
    final weightController =
        TextEditingController(text: record.weight.toString());

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Data BMI'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tinggi (cm)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Berat (kg)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final height = double.tryParse(heightController.text) ?? 0;
              final weight = double.tryParse(weightController.text) ?? 0;

              if (height <= 0 || weight <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mohon masukkan tinggi dan berat yang valid'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              _updateBMIRecord(record.id, height, weight);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog for deleting BMI record
  Future<void> _showDeleteConfirmation(IBMHistory record) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data BMI'),
        content: const Text(
            'Anda yakin ingin menghapus data BMI ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBMIRecord(record.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBMIRecord(String id, double height, double weight) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _bmiService.updateBMIRecord(
        id: id,
        height: height,
        weight: weight,
      );

      if (!mounted) return;

      if (response != null && response.success && response.data != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh BMI history
        _refreshBMIHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?.message ?? 'Gagal memperbarui data BMI'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteBMIRecord(String id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _bmiService.deleteBMIRecord(id: id);

      if (!mounted) return;

      if (response != null && response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh BMI history
        _refreshBMIHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?.message ?? 'Gagal menghapus data BMI'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Add this helper method for statistics display
  Widget _buildStatItem({required String title, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
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

  // Add this new method for the weight goal section
  Widget _buildWeightGoalSection() {
    return WeightGoalCard(
      onGoalCreated: () {
        // Refresh data if needed
      },
      onGoalUpdated: () {
        // Refresh data if needed
      },
      onGoalDeleted: () {
        // Refresh data if needed
      },
    );
  }
}
