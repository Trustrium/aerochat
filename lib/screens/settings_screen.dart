import 'package:flutter/material.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _configService = ConfigService();
  AppConfig? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _configService.loadConfig();
    setState(() {
      _config = config;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Settings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepPurple.shade700,
                      Colors.purple.shade500,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: 20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader('AI Providers'),
              ..._buildProviderCards(),
              _buildSectionHeader('Appearance'),
              _buildThemeCard(),
              _buildSectionHeader('About'),
              _buildAboutCard(),
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.purple.shade300,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  List<Widget> _buildProviderCards() {
    final providers = _config?.providerConfigs ?? [];
    return providers.map((provider) => _ProviderCard(
      config: provider,
      isActive: _config?.activeProvider?.provider == provider.provider,
      onTap: () => _showProviderConfig(provider),
    )).toList();
  }

  Widget _buildThemeCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.shade100.withOpacity(0.1)),
      ),
      color: Theme.of(context).cardColor.withOpacity(0.8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.shade900.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _config?.darkMode ?? true ? Icons.dark_mode : Icons.light_mode,
            color: Colors.purple.shade300,
          ),
        ),
        title: const Text('Dark Mode'),
        subtitle: Text(_config?.darkMode ?? true ? 'Enabled' : 'Disabled'),
        trailing: Switch(
          value: _config?.darkMode ?? true,
          onChanged: (value) async {
            await _configService.setDarkMode(value);
            setState(() {
              _config = _config?.copyWith(darkMode: value);
            });
          },
          activeColor: Colors.purple.shade400,
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.shade100.withOpacity(0.1)),
      ),
      color: Theme.of(context).cardColor.withOpacity(0.8),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline, color: Colors.purple.shade300),
            ),
            title: const Text('Version'),
            subtitle: const Text('1.0.0+1'),
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.code, color: Colors.purple.shade300),
            ),
            title: const Text('Open Source'),
            subtitle: const Text('Flutter Antigravity Clone'),
            trailing: const Icon(Icons.open_in_new, size: 18),
          ),
        ],
      ),
    );
  }

  void _showProviderConfig(ProviderConfig config) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProviderConfigSheet(
        config: config,
        onSave: (newConfig) async {
          await _configService.updateProviderConfig(newConfig);
          await _loadConfig();
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ProviderConfig config;
  final bool isActive;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.config,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isActive ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive
              ? Colors.purple.shade400
              : Colors.purple.shade100.withOpacity(0.1),
          width: isActive ? 2 : 1,
        ),
      ),
      color: isActive
          ? Colors.purple.shade900.withOpacity(0.3)
          : Theme.of(context).cardColor.withOpacity(0.8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: config.isEnabled
              ? Colors.green.shade700.withOpacity(0.3)
              : Colors.red.shade700.withOpacity(0.3),
          child: Icon(
            config.isEnabled ? Icons.check_circle : Icons.radio_button_unchecked,
            color: config.isEnabled ? Colors.green.shade300 : Colors.red.shade300,
          ),
        ),
        title: Text(
          config.provider.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(config.model),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade400.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ProviderConfigSheet extends StatefulWidget {
  final ProviderConfig config;
  final Function(ProviderConfig) onSave;

  const _ProviderConfigSheet({
    required this.config,
    required this.onSave,
  });

  @override
  State<_ProviderConfigSheet> createState() => _ProviderConfigSheetState();
}

class _ProviderConfigSheetState extends State<_ProviderConfigSheet> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelController;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.config.apiKey);
    _baseUrlController = TextEditingController(text: widget.config.baseUrl);
    _modelController = TextEditingController(text: widget.config.model);
    _isEnabled = widget.config.isEnabled;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade800, Colors.deepPurple.shade900],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.config.provider.displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            'Enabled',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _isEnabled,
                            onChanged: (value) => setState(() => _isEnabled = value),
                            activeColor: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    'API Key',
                    _apiKeyController,
                    'Enter your API key',
                    obscureText: true,
                    icon: Icons.key,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Base URL',
                    _baseUrlController,
                    'https://api.example.com',
                    icon: Icons.link,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Model',
                    _modelController,
                    'e.g., gpt-4, claude-3-sonnet',
                    icon: Icons.smart_toy,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Save Configuration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    required IconData icon,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.purple.shade300),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.purple.shade700.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.purple.shade400),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  void _saveConfig() {
    final newConfig = widget.config.copyWith(
      apiKey: _apiKeyController.text,
      baseUrl: _baseUrlController.text,
      model: _modelController.text,
      isEnabled: _isEnabled,
    );
    widget.onSave(newConfig);
  }
}
