import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bmi_goal.dart';
import '../../utils/app_colors.dart';
import '../../services/bmi_service.dart';

class WeightGoalCard extends StatefulWidget {
  final BMIGoal? initialGoal;
  final Function? onGoalCreated;
  final Function? onGoalUpdated;
  final Function? onGoalDeleted;

  const WeightGoalCard({
    super.key,
    this.initialGoal,
    this.onGoalCreated,
    this.onGoalUpdated,
    this.onGoalDeleted,
  });

  @override
  State<WeightGoalCard> createState() => _WeightGoalCardState();
}

class _WeightGoalCardState extends State<WeightGoalCard> {
  BMIGoal? _goal;
  bool _isLoading = false;
  final BMIService _bmiService = BMIService();

  @override
  void initState() {
    super.initState();
    _goal = widget.initialGoal;
    if (_goal == null) {
      _loadActiveGoal();
    }
  }

  Future<void> _loadActiveGoal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _bmiService.getActiveBMIGoal();
      if (mounted) {
        setState(() {
          _goal = response?.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double _calculateProgress() {
    if (_goal == null) return 0.0;

    // Use the API-provided progress if available
    if (_goal!.progress > 0) {
      return _goal!.progress;
    }

    final startWeight = _goal!.startWeight;
    final targetWeight = _goal!.targetWeight;
    final currentWeight =
        _goal!.currentWeight > 0 ? _goal!.currentWeight : _goal!.startWeight;

    // If target is to gain weight
    if (targetWeight > startWeight) {
      if (currentWeight >= targetWeight) return 1.0;
      if (currentWeight <= startWeight) return 0.0;
      return (currentWeight - startWeight) / (targetWeight - startWeight);
    }
    // If target is to lose weight
    else if (targetWeight < startWeight) {
      if (currentWeight <= targetWeight) return 1.0;
      if (currentWeight >= startWeight) return 0.0;
      return (startWeight - currentWeight) / (startWeight - targetWeight);
    }

    // If target is same as start (maintain weight)
    return 1.0;
  }

  int _calculateDaysLeft() {
    if (_goal == null) return 0;

    final now = DateTime.now();
    final targetDate = _goal!.targetDate;

    final difference = targetDate.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<void> _showCreateGoalDialog() async {
    final weightController = TextEditingController();
    final targetDateController = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Target Berat Badan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Berat (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  targetDateController.text = _formatDate(picked);
                  selectedDate = picked;
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: targetDateController,
                  decoration: const InputDecoration(
                    labelText: 'Target Tanggal',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
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
            onPressed: () async {
              if (weightController.text.isEmpty || selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mohon isi semua field'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final targetWeight = double.tryParse(weightController.text);
              if (targetWeight == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Berat harus berupa angka'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _createGoal(targetWeight, selectedDate!);
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

  Future<void> _createGoal(double targetWeight, DateTime targetDate) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _bmiService.createBMIGoal(
        targetWeight: targetWeight,
        targetDate: targetDate,
      );

      if (!mounted) return;

      if (response != null && response.success && response.data != null) {
        setState(() {
          _goal = response.data;
          _isLoading = false;
        });

        if (widget.onGoalCreated != null) {
          widget.onGoalCreated!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response?.message ?? 'Gagal membuat target berat badan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showEditGoalDialog() async {
    if (_goal == null) return;

    final weightController =
        TextEditingController(text: _goal!.targetWeight.toString());
    final targetDateController =
        TextEditingController(text: _formatDate(_goal!.targetDate));
    DateTime? selectedDate = _goal!.targetDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Target Berat Badan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Berat (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _goal!.targetDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  targetDateController.text = _formatDate(picked);
                  selectedDate = picked;
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: targetDateController,
                  decoration: const InputDecoration(
                    labelText: 'Target Tanggal',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
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
            onPressed: () async {
              if (weightController.text.isEmpty || selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mohon isi semua field'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final targetWeight = double.tryParse(weightController.text);
              if (targetWeight == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Berat harus berupa angka'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _updateGoal(_goal!.id, targetWeight, selectedDate!);
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

  Future<void> _updateGoal(
      String id, double targetWeight, DateTime targetDate) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _bmiService.updateBMIGoal(
        id: id,
        targetWeight: targetWeight,
        targetDate: targetDate,
      );

      if (!mounted) return;

      if (response != null && response.success && response.data != null) {
        setState(() {
          _goal = response.data;
          _isLoading = false;
        });

        if (widget.onGoalUpdated != null) {
          widget.onGoalUpdated!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                response?.message ?? 'Gagal mengupdate target berat badan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    if (_goal == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Target Berat Badan'),
        content:
            const Text('Anda yakin ingin menghapus target berat badan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGoal(_goal!.id);
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

  Future<void> _deleteGoal(String id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _bmiService.deleteBMIGoal(id: id);

      if (!mounted) return;

      if (response != null && response.success) {
        setState(() {
          _goal = null;
          _isLoading = false;
        });

        if (widget.onGoalDeleted != null) {
          widget.onGoalDeleted!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response?.message ?? 'Gagal menghapus target berat badan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_goal == null) {
      return _buildEmptyGoalCard();
    }

    return _buildGoalCard();
  }

  Widget _buildEmptyGoalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Target Berat Badan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Buat target berat badan untuk membantu Anda mencapai tujuan kebugaran',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showCreateGoalDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Buat Target Berat'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard() {
    final progress = _calculateProgress();

    // Determine if target is to gain or lose weight
    final isGain = _goal!.targetWeight > _goal!.startWeight;
    final isDone = progress >= 1.0;
    final isExpired = _goal!.targetDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
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
                'Target Berat Badan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: _showEditGoalDialog,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: _showDeleteConfirmation,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weight info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeightInfo(
                  'Berat Awal', '${_goal!.startWeight} kg', Colors.grey),
              _buildWeightInfo(
                  'Berat Saat Ini',
                  '${_goal!.currentWeight > 0 ? _goal!.currentWeight : _goal!.startWeight} kg',
                  AppColors.secondary),
              _buildWeightInfo('Target Berat', '${_goal!.targetWeight} kg',
                  AppColors.primary),
            ],
          ),

          const SizedBox(height: 16),

          // Weight change info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeightInfo(
                  isGain ? 'Berat Bertambah' : 'Berat Berkurang',
                  '${_goal!.weightLost.abs().toStringAsFixed(1)} kg',
                  _goal!.weightLost != 0
                      ? (isGain ? Colors.green : Colors.orange)
                      : Colors.grey),
              _buildWeightInfo(
                  isGain ? 'Perlu Bertambah' : 'Perlu Berkurang',
                  '${_goal!.weightRemaining.abs().toStringAsFixed(1)} kg',
                  _goal!.weightRemaining != 0
                      ? AppColors.primary
                      : Colors.grey),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDone ? Colors.green : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDone ? Colors.green : AppColors.primary,
                  ),
                  minHeight: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Date info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal Mulai',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    _formatDate(_goal!.startDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Target Tanggal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    _formatDate(_goal!.targetDate),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isExpired ? Colors.red : null,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: _getStatusColor().withOpacity(0.5),
                ),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    if (_goal == null) return '';

    final progress = _calculateProgress();
    final daysLeft = _calculateDaysLeft();
    final isExpired = _goal!.targetDate.isBefore(DateTime.now());

    if (progress >= 1.0) {
      return 'Target Tercapai';
    } else if (isExpired) {
      return 'Tenggat Waktu Terlewat';
    } else {
      return '$daysLeft hari tersisa';
    }
  }

  Color _getStatusColor() {
    if (_goal == null) return Colors.grey;

    final progress = _calculateProgress();
    final isExpired = _goal!.targetDate.isBefore(DateTime.now());

    if (progress >= 1.0) {
      return Colors.green;
    } else if (isExpired) {
      return Colors.red;
    } else {
      return AppColors.primary;
    }
  }
}
