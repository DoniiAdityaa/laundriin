import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  int _currentStep = 1; // Step 1: Customer Info

  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();

  String _selectedGender = 'Laki-laki'; // Default gender

  // Firestore & Auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Customer search state
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSuggestions = false;
  String? _selectedCustomerId; // Track if customer is from database

  // ====== STEP 2: SERVICE ORDER STATE ======
  String _selectedCategory = 'Kiloan'; // Kiloan / Non-kiloan / Mixed
  String _selectedSpeed = 'Regular'; // Regular / Express
  final _weightC = TextEditingController(); // For Kiloan/Mixed
  final _qtyC = TextEditingController(); // For Non-kiloan/Mixed
  final _notesC = TextEditingController(); // Special notes

  // Pricing from database
  int _pricePerKilo = 0;
  int _expressSurcharge = 0;

  @override
  void initState() {
    super.initState();
    _nameC.addListener(_onNameChanged);
    _loadPricingData();
  }

  Future<void> _loadPricingData() async {
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final pricing = doc.data()!['pricing'] ?? {};
        setState(() {
          _pricePerKilo = pricing['pricePerKilo'] ?? 0;
          _expressSurcharge = pricing['expressSurcharge'] ?? 0;
        });
        print(
            '[LOAD] Pricing data: ${_pricePerKilo}/kg, Express: +${_expressSurcharge}');
      }
    } catch (e) {
      print('[ERROR] Load pricing: $e');
    }
  }

  void _onNameChanged() {
    if (_nameC.text.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
        _selectedCustomerId = null;
      });
      return;
    }

    _searchCustomers(_nameC.text.trim());
  }

  Future<void> _searchCustomers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('shops')
          .doc(_userId)
          .collection('customers')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      setState(() {
        _searchResults = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
        _showSuggestions = _searchResults.isNotEmpty;
      });

      print(
          '[SEARCH] Found ${_searchResults.length} customers matching "$query"');
    } catch (e) {
      print('[ERROR] Search customers: $e');
    }
  }

  void _selectCustomer(Map<String, dynamic> customer) {
    setState(() {
      _nameC.text = customer['name'] ?? '';
      _phoneC.text = customer['phone'] ?? '';
      _selectedGender = customer['gender'] ?? 'Laki-laki';
      _selectedCustomerId = customer['id'];
      _showSuggestions = false;
      _searchResults = [];
    });

    print(
        '[SELECT] Customer selected: ${customer['name']} (${customer['id']})');
  }

  void _clearCustomerSelection() {
    setState(() {
      _nameC.clear();
      _phoneC.clear();
      _selectedGender = 'Laki-laki';
      _selectedCustomerId = null;
      _showSuggestions = false;
      _searchResults = [];
    });

    print('[CLEAR] Customer selection cleared');
  }

  Future<void> _saveNewCustomer() async {
    try {
      final customerId = _firestore
          .collection('shops')
          .doc(_userId)
          .collection('customers')
          .doc()
          .id;

      await _firestore
          .collection('shops')
          .doc(_userId)
          .collection('customers')
          .doc(customerId)
          .set({
        'name': _nameC.text.trim(),
        'phone': _phoneC.text.trim(),
        'gender': _selectedGender,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _selectedCustomerId = customerId;
      print('[SAVE] New customer created: $_selectedCustomerId');
    } catch (e) {
      print('[ERROR] Save customer: $e');
      throw e;
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _weightC.dispose();
    _qtyC.dispose();
    _notesC.dispose();
    super.dispose();
  }

  void _nextStep() async {
    // Validate step 1
    if (_nameC.text.trim().isEmpty || _phoneC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dan nomor HP wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save new customer if not selected from database
    if (_selectedCustomerId == null) {
      try {
        await _saveNewCustomer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pelanggan baru tersimpan'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal simpan pelanggan: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Move to next step
    setState(() => _currentStep = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Header =====
              _buildHeader(),
              const SizedBox(height: 24),

              // ===== Step Indicator =====
              _buildStepIndicator(),
              const SizedBox(height: 24),

              // ===== Step Content =====
              if (_currentStep == 1) _buildStep1(),
              if (_currentStep == 2) _buildStep2(),

              const SizedBox(height: 32),

              // ===== Navigation Buttons =====
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Header =====
  Widget _buildHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Order', style: mBold),
                const SizedBox(height: 4),
                Text(
                  'Create new order for customer',
                  style: sRegular.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===== Step Indicator =====
  Widget _buildStepIndicator() {
    return Row(
      children: [
        // Step 1
        _buildStepDot(1),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: _currentStep > 1 ? blue500 : const Color(0xFFE5E7EB),
          ),
        ),
        // Step 2
        _buildStepDot(2),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: _currentStep > 2 ? blue500 : const Color(0xFFE5E7EB),
          ),
        ),
        // Step 3
        _buildStepDot(3),
      ],
    );
  }

  Widget _buildStepDot(int step) {
    final isActive = _currentStep >= step;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? blue500 : const Color(0xFFE5E7EB),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[500],
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ===== Step 1: Customer Info =====
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Customer Information', style: mBold),
        const SizedBox(height: 4),
        Text(
          'Enter customer details to create order',
          style: sRegular.copyWith(color: const Color(0xFF6B7280)),
        ),
        const SizedBox(height: 20),

        // ===== Name Field with Autocomplete =====
        Text('Customer Name', style: smBold),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameC,
              textCapitalization: TextCapitalization.words,
              style: smBold.copyWith(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. Budi Santoso',
                hintStyle: sRegular.copyWith(color: textMuted),
                filled: true,
                fillColor: bgInput,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderFocus, width: 1.2),
                ),
              ),
            ),

            // Suggestions Dropdown - Only show jika belum ada customer dipilih
            if (_showSuggestions &&
                _searchResults.isNotEmpty &&
                _selectedCustomerId == null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: borderLight,
                  ),
                  itemBuilder: (context, index) {
                    final customer = _searchResults[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        customer['name'] ?? '',
                        style: smBold.copyWith(color: textPrimary),
                      ),
                      subtitle: Text(
                        customer['phone'] ?? '',
                        style: xsRegular.copyWith(color: textMuted),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        iconSize: 20,
                        color: Colors.red[400],
                        onPressed: () => _clearCustomerSelection(),
                      ),
                      onTap: () => _selectCustomer(customer),
                    );
                  },
                ),
              ),
          ],
        ),

        const SizedBox(height: 18),

        // ===== Gender Field =====
        Text('Jenis Kelamin', style: smBold),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = 'Laki-laki'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'Laki-laki' ? blue500 : bgInput,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGender == 'Laki-laki'
                          ? blue500
                          : borderLight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Laki-laki',
                      style: smBold.copyWith(
                        color: _selectedGender == 'Laki-laki'
                            ? Colors.white
                            : textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = 'Perempuan'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'Perempuan' ? blue500 : bgInput,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGender == 'Perempuan'
                          ? blue500
                          : borderLight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Perempuan',
                      style: smBold.copyWith(
                        color: _selectedGender == 'Perempuan'
                            ? Colors.white
                            : textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // ===== Phone Field =====
        Text('Phone Number', style: smBold),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneC,
          keyboardType: TextInputType.phone,
          style: smBold.copyWith(color: textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. 082123456789',
            hintStyle: sRegular.copyWith(color: textMuted),
            filled: true,
            fillColor: bgInput,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixText: '+62 ',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderFocus, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  // ===== Bottom Navigation Buttons =====
  Widget _buildBottomButtons() {
    return Row(
      children: [
        // Back Button
        if (_currentStep > 1)
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderLight, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Back',
                  style: smBold.copyWith(color: textPrimary),
                ),
              ),
            ),
          ),

        if (_currentStep > 1) const SizedBox(width: 12),

        // Next/Continue Button
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: blue500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: blue500.withOpacity(0.3),
              ),
              child: Text(
                'Next',
                style: smBold.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ====== STEP 2: SERVICE ORDER ======
  Widget _buildStep2() {
    // Calculate price based on selections
    int basePrice = 0;
    if (_selectedCategory == 'Kiloan' && _weightC.text.isNotEmpty) {
      final weight = double.tryParse(_weightC.text) ?? 0;
      basePrice = (_pricePerKilo * weight).toInt();
    }

    int expressPrice = (_selectedSpeed == 'Express') ? _expressSurcharge : 0;
    int totalPrice = basePrice + expressPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Order Type', style: mBold),
        const SizedBox(height: 20),

        // ===== Category Selection =====
        Text('Category', style: smBold),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildCategoryButton('Kiloan'),
            const SizedBox(width: 12),
            _buildCategoryButton('Non-kiloan'),
            const SizedBox(width: 12),
            _buildCategoryButton('Mixed'),
          ],
        ),

        const SizedBox(height: 20),

        // ===== Speed Selection =====
        Text('Service Speed', style: smBold),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSpeed = 'Regular'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedSpeed == 'Regular' ? blue500 : bgInput,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _selectedSpeed == 'Regular' ? blue500 : borderLight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Regular',
                      style: smBold.copyWith(
                        color: _selectedSpeed == 'Regular'
                            ? Colors.white
                            : textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSpeed = 'Express'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedSpeed == 'Express' ? blue500 : bgInput,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _selectedSpeed == 'Express' ? blue500 : borderLight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Express',
                          style: smBold.copyWith(
                            color: _selectedSpeed == 'Express'
                                ? Colors.white
                                : textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+Rp ${_formatNumber(_expressSurcharge)}',
                          style: xsRegular.copyWith(
                            color: _selectedSpeed == 'Express'
                                ? Colors.white70
                                : textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ===== Input based on Category =====
        if (_selectedCategory == 'Kiloan') ...[
          Text('Weight (kg)', style: smBold),
          const SizedBox(height: 8),
          TextField(
            controller: _weightC,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: smBold.copyWith(color: textPrimary),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. 2.5',
              hintStyle: sRegular.copyWith(color: textMuted),
              filled: true,
              fillColor: bgInput,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixText: 'kg',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderFocus, width: 1.2),
              ),
            ),
          ),
        ] else if (_selectedCategory == 'Non-kiloan') ...[
          Text('Item', style: smBold),
          const SizedBox(height: 8),
          TextField(
            controller: _qtyC,
            keyboardType: TextInputType.number,
            style: smBold.copyWith(color: textPrimary),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. 3',
              hintStyle: sRegular.copyWith(color: textMuted),
              filled: true,
              fillColor: bgInput,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixText: 'items',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderFocus, width: 1.2),
              ),
            ),
          ),
        ] else ...[
          // Mixed
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weight (kg)', style: smBold),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _weightC,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: smBold.copyWith(color: textPrimary),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '2.5',
                        hintStyle: sRegular.copyWith(color: textMuted),
                        filled: true,
                        fillColor: bgInput,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: borderFocus, width: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Item Qty', style: smBold),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _qtyC,
                      keyboardType: TextInputType.number,
                      style: smBold.copyWith(color: textPrimary),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '3',
                        hintStyle: sRegular.copyWith(color: textMuted),
                        filled: true,
                        fillColor: bgInput,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: borderFocus, width: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 20),

        // ===== Special Notes =====
        Text('Special Notes (Optional)', style: smBold),
        const SizedBox(height: 8),
        TextField(
          controller: _notesC,
          maxLines: 3,
          style: sRegular.copyWith(color: textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Gunakan deterjen lembut, jangan putar kering...',
            hintStyle: sRegular.copyWith(color: textMuted),
            filled: true,
            fillColor: bgInput,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderFocus, width: 1.2),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ===== Price Summary =====
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Price Summary', style: smBold),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Base Price:',
                    style: sRegular.copyWith(color: textSecondary),
                  ),
                  Text(
                    'Rp ${_formatNumber(basePrice)}',
                    style: smBold.copyWith(color: textPrimary),
                  ),
                ],
              ),
              if (_selectedSpeed == 'Express') ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Express Surcharge:',
                      style: sRegular.copyWith(color: textSecondary),
                    ),
                    Text(
                      '+Rp ${_formatNumber(expressPrice)}',
                      style: smBold.copyWith(color: Colors.orange[700]),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Divider(color: borderLight),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: mBold,
                  ),
                  Text(
                    'Rp ${_formatNumber(totalPrice)}',
                    style: mBold.copyWith(color: blue500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== Helper: Category Button with Image =====
  Widget _buildCategoryButton(String category) {
    final isSelected = _selectedCategory == category;

    // Map category ke image path
    final imageMap = {
      'Kiloan': 'assets/images/Balance_Scale.png',
      'Non-kiloan': 'assets/images/shirt.png',
      'Mixed': 'assets/images/package.png',
    };

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: Container(
          width: double.infinity,
          height: 125, // Lebih besar untuk semua sama
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? blue500.withOpacity(0.1) : bgInput,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? blue500 : borderLight,
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image
              Image.asset(
                imageMap[category]!,
                height: 40,
                width: 40,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              // Text
              Text(
                category,
                textAlign: TextAlign.center,
                style: sBold.copyWith(
                  color: isSelected ? blue500 : textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Helper: Format Number =====
  String _formatNumber(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (Match m) => '.',
        );
  }
}
