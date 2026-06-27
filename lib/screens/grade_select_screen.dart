import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pet_cubit.dart';

class GradeSelectScreen extends StatefulWidget {
  const GradeSelectScreen({super.key});

  @override
  State<GradeSelectScreen> createState() => _GradeSelectScreenState();
}

class _GradeSelectScreenState extends State<GradeSelectScreen> {
  int? _selectedGrade;

  String _gradeLabel(int grade) {
    if (grade <= 2) return '小学低年级';
    if (grade <= 6) return '小学高年级';
    if (grade <= 9) return '初中';
    return '高中';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                '选择你的年级',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                '宠物会根据你的年级推送适合的知识和规劝文案',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final grade = index + 1;
                    final isSelected = _selectedGrade == grade;
                    return InkWell(
                      onTap: () => setState(() => _selectedGrade = grade),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$grade',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              '年级',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white70 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_selectedGrade != null)
                Center(
                  child: Text(
                    '已选择：${_gradeLabel(_selectedGrade!)}（${_selectedGrade!} 年级）',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedGrade == null
                      ? null
                      : () {
                          context.read<PetCubit>().selectGrade(_selectedGrade!);
                        },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '开始养宠物',
                    style: TextStyle(fontSize: 18),
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
