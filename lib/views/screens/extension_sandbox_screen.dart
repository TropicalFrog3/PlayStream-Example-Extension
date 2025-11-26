import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/extension/extension_metadata.dart';
import '../../models/extension/console_log_entry.dart';
import '../../models/extension/search_options.dart';
import '../../models/extension/media.dart';
import '../../models/extension/fuzzy_date.dart';
import '../../services/extension/extension_manager.dart';
import '../../controllers/movie_controller.dart';

/// Extension Sandbox Screen for testing extension methods
class ExtensionSandboxScreen extends ConsumerStatefulWidget {
  const ExtensionSandboxScreen({super.key});

  @override
  ConsumerState<ExtensionSandboxScreen> createState() => _ExtensionSandboxScreenState();
}

class _ExtensionSandboxScreenState extends ConsumerState<ExtensionSandboxScreen> with SingleTickerProviderStateMixin {
  // State persistence keys
  static const String _keySelectedMethod = 'extension_sandbox_selected_method';
  static const String _keyMediaTitle = 'extension_sandbox_media_title';
  static const String _keySelectedExtensionId = 'extension_sandbox_selected_extension_id';
  
  // State variables for user inputs
  String? _selectedExtensionId;
  String _selectedMethod = 'search';
  final TextEditingController _mediaTitleController = TextEditingController();
  final TextEditingController _seasonController = TextEditingController();
  final TextEditingController _episodeController = TextEditingController();
  final TextEditingController _imdbIdController = TextEditingController();
  final TextEditingController _tmdbIdController = TextEditingController();
  final TextEditingController _serverNameController = TextEditingController(text: 'vidking');
  String? _selectedMediaType;
  
  // State variables for execution results
  String _output = '';
  List<ConsoleLogEntry> _consoleLogs = [];
  bool _isExecuting = false;
  
  // Scroll controllers for auto-scroll
  final ScrollController _logsScrollController = ScrollController();
  final ScrollController _outputScrollController = ScrollController();
  
  // Flag to track if state has been restored
  bool _stateRestored = false;
  
  // Animation controller for smooth transitions
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _restoreState();
  }

  @override
  void dispose() {
    _mediaTitleController.dispose();
    _seasonController.dispose();
    _episodeController.dispose();
    _imdbIdController.dispose();
    _tmdbIdController.dispose();
    _serverNameController.dispose();
    _logsScrollController.dispose();
    _outputScrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  /// Restore saved state from shared preferences
  Future<void> _restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final savedMethod = prefs.getString(_keySelectedMethod);
      final savedMediaTitle = prefs.getString(_keyMediaTitle);
      final savedExtensionId = prefs.getString(_keySelectedExtensionId);
      
      if (mounted) {
        setState(() {
          if (savedMethod != null) {
            // Migrate old method names to new ones
            if (savedMethod == 'findEpisode') {
              _selectedMethod = 'findEpisodes';
            } else if (savedMethod == 'findEpisodeServers') {
              _selectedMethod = 'findEpisodeServer';
            } else {
              _selectedMethod = savedMethod;
            }
          }
          if (savedMediaTitle != null) {
            _mediaTitleController.text = savedMediaTitle;
          }
          if (savedExtensionId != null) {
            _selectedExtensionId = savedExtensionId;
          }
          _stateRestored = true;
        });
      }
    } catch (e) {
      // If restoration fails, just continue with default values
      debugPrint('Failed to restore sandbox state: $e');
      if (mounted) {
        setState(() {
          _stateRestored = true;
        });
      }
    }
  }
  
  /// Save current state to shared preferences
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_keySelectedMethod, _selectedMethod);
      await prefs.setString(_keyMediaTitle, _mediaTitleController.text.trim());
      if (_selectedExtensionId != null) {
        await prefs.setString(_keySelectedExtensionId, _selectedExtensionId!);
      }
    } catch (e) {
      // If saving fails, just continue - not critical
      debugPrint('Failed to save sandbox state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final installedExtensions = ref.watch(extensionManagerProvider).getInstalledExtensions();
    final enabledExtensions = installedExtensions.where((e) => e.isEnabled).toList();

    // Auto-select first extension if none selected and state has been restored
    if (_stateRestored && _selectedExtensionId == null && enabledExtensions.isNotEmpty) {
      // Check if saved extension is still available
      final savedExtensionAvailable = enabledExtensions.any((e) => e.id == _selectedExtensionId);
      
      if (!savedExtensionAvailable) {
        // Saved extension not available, select first one
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedExtensionId = enabledExtensions.first.id;
            });
            _saveState();
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Extension Sandbox'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Extension selector
              _buildExtensionSelector(enabledExtensions),
              const SizedBox(height: 20),
              
              // Method selector
              _buildMethodSelector(),
              const SizedBox(height: 20),
              
              // Dynamic input fields
              _buildInputFields(),
              const SizedBox(height: 20),
              
              // Execute button
              _buildExecuteButton(),
              const SizedBox(height: 32),
              
              // Output section
              _buildOutputSection(),
              const SizedBox(height: 32),
              
              // Console logs section
              _buildConsoleLogsSection(),
              
              // Bottom padding for better scrolling
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildExtensionSelector(List<ExtensionMetadata> enabledExtensions) {
    if (enabledExtensions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No extensions installed. Please install an extension first.',
                style: TextStyle(
                  color: Colors.orange[300],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Check if selected extension is still available
    final isSelectedExtensionAvailable = enabledExtensions.any((e) => e.id == _selectedExtensionId);
    if (!isSelectedExtensionAvailable && _selectedExtensionId != null) {
      // Selected extension was removed or disabled, show warning
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showErrorSnackBar('Previously selected extension is no longer available');
          setState(() {
            _selectedExtensionId = null;
            _output = '';
            _consoleLogs = [];
          });
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Extension',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: isSelectedExtensionAvailable ? _selectedExtensionId : null,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: 'Select an extension',
              hintStyle: TextStyle(color: Colors.grey[600]),
            ),
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white, fontSize: 16),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
            items: enabledExtensions.map((extension) {
              return DropdownMenuItem(
                value: extension.id,
                child: Text(extension.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedExtensionId = value;
                // Clear output when switching extensions
                _output = '';
                _consoleLogs = [];
              });
              // Save state when extension changes
              _saveState();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Method',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedMethod,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white, fontSize: 16),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
            items: const [
              DropdownMenuItem(value: 'search', child: Text('search')),
              DropdownMenuItem(value: 'findEpisodes', child: Text('findEpisodes')),
              DropdownMenuItem(value: 'findEpisodeServer', child: Text('findEpisodeServer')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedMethod = value!;
                // Clear season/episode fields when switching to search
                if (_selectedMethod == 'search') {
                  _seasonController.clear();
                  _episodeController.clear();
                }
              });
              // Save state when method changes
              _saveState();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    final isSearchMethod = _selectedMethod == 'search';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Media Title field
        Text(
          _selectedMethod == 'search' ? 'Media Title (optional if ID provided)' : (_selectedMethod == 'findEpisodes' ? 'Show ID' : 'Episode ID'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _mediaTitleController,
          onChanged: (_) {
            setState(() {}); // Trigger rebuild for validation
            _saveState(); // Save state when media title changes
          },
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: _selectedMethod == 'search' ? 'Enter media title (or use TMDB/IMDB ID below)' : (_selectedMethod == 'findEpisodes' ? 'e.g. tv:114472' : 'e.g. tv:114472:1:1'),
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        
        // IMDB ID and TMDB ID fields (only for search method)
        if (isSearchMethod) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IMDB ID (optional)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _imdbIdController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'e.g. tt1234567',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[800]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[800]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TMDB ID (optional)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tmdbIdController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'e.g. 12345',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[800]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[800]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Media Type (optional)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedMediaType,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    hintText: 'Select media type',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Auto (default)')),
                    DropdownMenuItem(value: 'movie', child: Text('Movie')),
                    DropdownMenuItem(value: 'tv', child: Text('TV Show')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMediaType = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
        
        // Server name field (only for findEpisodeServer method)
        if (_selectedMethod == 'findEpisodeServer') ...[
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Server Name',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _serverNameController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'e.g. vidking',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
          ),
        ],

      ],
    );
  }



  Widget _buildExecuteButton() {
    final isValid = _isInputValid();
    final validationError = _getInputValidationError();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isValid && !_isExecuting ? _executeExtension : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[800],
              disabledForegroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isExecuting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Execute',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        if (!isValid && validationError != null) ...[
          const SizedBox(height: 12),
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red[300], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      validationError,
                      style: TextStyle(
                        color: Colors.red[300],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOutputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Output',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: _output.isNotEmpty ? _copyOutput : null,
                  tooltip: 'Copy output',
                  color: _output.isNotEmpty ? Colors.white70 : Colors.grey[700],
                  splashRadius: 20,
                ),
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: _output.isNotEmpty ? _clearOutput : null,
                  tooltip: 'Clear output',
                  color: _output.isNotEmpty ? Colors.white70 : Colors.grey[700],
                  splashRadius: 20,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'Extension execution output',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: _output.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.code_rounded,
                        size: 48,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No output yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : Scrollbar(
                  controller: _outputScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _outputScrollController,
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      _output,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsoleLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Console Logs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: _consoleLogs.isNotEmpty ? _copyConsoleLogs : null,
                  tooltip: 'Copy all logs',
                  color: _consoleLogs.isNotEmpty ? Colors.white70 : Colors.grey[700],
                  splashRadius: 20,
                ),
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: _consoleLogs.isNotEmpty ? _clearLogs : null,
                  tooltip: 'Clear logs',
                  color: _consoleLogs.isNotEmpty ? Colors.white70 : Colors.grey[700],
                  splashRadius: 20,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'Console logs from extension execution',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: _consoleLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.terminal_rounded,
                        size: 48,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No logs yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : Scrollbar(
                  controller: _logsScrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _logsScrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _consoleLogs.length,
                    itemBuilder: (context, index) {
                      final log = _consoleLogs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SelectableText(
                          '${log.formattedTimestamp} ${log.levelPrefix} ${log.message}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: _getLogColor(log.level),
                            height: 1.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Color _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warn:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  bool _isInputValid() {
    if (_selectedExtensionId == null) return false;
    
    // For search method, allow empty media title if TMDB or IMDB ID is provided
    if (_selectedMethod == 'search') {
      final hasMediaTitle = _mediaTitleController.text.trim().isNotEmpty;
      final hasTmdbId = _tmdbIdController.text.trim().isNotEmpty;
      final hasImdbId = _imdbIdController.text.trim().isNotEmpty;
      
      return hasMediaTitle || hasTmdbId || hasImdbId;
    }
    
    // For other methods, media title/ID is required
    if (_mediaTitleController.text.trim().isEmpty) return false;
    
    return true;
  }

  String? _getInputValidationError() {
    if (_selectedExtensionId == null) {
      return 'Please select an extension';
    }
    
    if (_selectedMethod == 'search') {
      final hasMediaTitle = _mediaTitleController.text.trim().isNotEmpty;
      final hasTmdbId = _tmdbIdController.text.trim().isNotEmpty;
      final hasImdbId = _imdbIdController.text.trim().isNotEmpty;
      
      if (!hasMediaTitle && !hasTmdbId && !hasImdbId) {
        return 'Please enter a media title, TMDB ID, or IMDB ID';
      }
    } else if (_mediaTitleController.text.trim().isEmpty) {
      if (_selectedMethod == 'findEpisodes') {
        return 'Please enter a show ID (e.g. tv:114472)';
      } else {
        return 'Please enter an episode ID (e.g. tv:114472:1:1)';
      }
    }
    
    return null;
  }

  Future<void> _executeExtension() async {
    // Validate inputs before execution
    if (!_isInputValid()) {
      final error = _getInputValidationError();
      if (error != null) {
        _showErrorSnackBar(error);
      }
      return;
    }

    // Check if extension is still available
    final installedExtensions = ref.read(extensionManagerProvider).getInstalledExtensions();
    final selectedExtension = installedExtensions.firstWhere(
      (e) => e.id == _selectedExtensionId,
      orElse: () => throw StateError('Extension not found'),
    );

    if (!selectedExtension.isEnabled) {
      _showErrorSnackBar('Selected extension is disabled. Please enable it first.');
      return;
    }

    setState(() {
      _isExecuting = true;
      _output = '';
      _consoleLogs = [];
    });
    
    // Start animation
    _animationController.forward();

    try {
      final manager = ref.read(extensionManagerProvider);
      
      // Build arguments based on selected method
      final args = <String, dynamic>{};
      
      if (_selectedMethod == 'search') {
        // Build SearchOptions object for the new architecture
        final imdbId = _imdbIdController.text.trim();
        final tmdbId = _tmdbIdController.text.trim();
        final mediaTitle = _mediaTitleController.text.trim();
        
        // Query is required - use media title, or fallback to TMDB/IMDB ID, or use placeholder
        String query = mediaTitle;
        if (query.isEmpty) {
          if (tmdbId.isNotEmpty) {
            query = 'TMDB:$tmdbId';
          } else if (imdbId.isNotEmpty) {
            query = 'IMDB:$imdbId';
          } else {
            query = 'search'; // Fallback placeholder
          }
        }
        
        // Fetch metadata from Trakt if TMDB or IMDB ID is provided
        Media? media;
        
        if (tmdbId.isNotEmpty || imdbId.isNotEmpty) {
          try {
            final traktClient = ref.read(traktClientProvider);
            
            // Determine ID type and value
            final idType = tmdbId.isNotEmpty ? 'tmdb' : 'imdb';
            final idValue = tmdbId.isNotEmpty ? tmdbId : imdbId;
            
            // Search by ID using Trakt ID Lookup endpoint
            // The endpoint is: GET /search/:id_type/:id
            final searchResults = await traktClient.search.idLookup(
              idType: idType,
              id: idValue,
              type: _selectedMediaType, // Can be 'movie', 'show', or null for auto-detect
            );
            
            if (searchResults.isNotEmpty) {
              final result = searchResults.first;
              
              // Extract media info based on type
              if (result['type'] == 'movie' && result['movie'] != null) {
                final movie = result['movie'];
                final ids = movie['ids'] as Map<String, dynamic>?;
                
                media = Media(
                  id: ids?['trakt'] ?? 0,
                  imdbId: ids?['imdb'],
                  tmdbId: ids?['tmdb']?.toString(),
                  format: 'MOVIE',
                  englishTitle: movie['title'],
                  synonyms: [],
                  isAdult: false,
                  startDate: movie['released'] != null 
                    ? _parseFuzzyDate(movie['released']) 
                    : null,
                );
              } else if (result['type'] == 'show' && result['show'] != null) {
                final show = result['show'];
                final ids = show['ids'] as Map<String, dynamic>?;
                
                media = Media(
                  id: ids?['trakt'] ?? 0,
                  imdbId: ids?['imdb'],
                  tmdbId: ids?['tmdb']?.toString(),
                  format: 'TV',
                  englishTitle: show['title'],
                  synonyms: [],
                  isAdult: false,
                  startDate: show['first_aired'] != null 
                    ? _parseFuzzyDate(show['first_aired']) 
                    : null,
                );
              }
            }
          } catch (e) {
            // If Trakt fetch fails, log but continue with basic media object
            debugPrint('Failed to fetch metadata from Trakt: $e');
          }
        }
        
        // Fallback to basic Media object if Trakt fetch failed or no IDs provided
        media ??= Media(
          id: 0,
          imdbId: imdbId.isNotEmpty ? imdbId : null,
          tmdbId: tmdbId.isNotEmpty ? tmdbId : null,
          format: _selectedMediaType?.toUpperCase(),
          englishTitle: mediaTitle.isNotEmpty ? mediaTitle : null,
          synonyms: [],
          isAdult: false,
        );
        
        // Create SearchOptions object
        final searchOptions = SearchOptions(
          media: media,
          query: query, // Now guaranteed to be non-empty
          year: null, // Could add a year field to the UI later
        );
        
        // Convert to JSON for method channel
        args['searchOptions'] = searchOptions.toJson();
      } else if (_selectedMethod == 'findEpisodes') {
        args['id'] = _mediaTitleController.text.trim();
      } else if (_selectedMethod == 'findEpisodeServer') {
        // For findEpisodeServer, we need to parse the episode ID and create EpisodeDetails
        final episodeId = _mediaTitleController.text.trim();
        final serverName = _serverNameController.text.trim();
        
        // Parse episode ID (format: tv:tmdbId:season:episode or movie:tmdbId)
        final parts = episodeId.split(':');
        
        if (parts.isNotEmpty) {
          // Create a minimal EpisodeDetails object
          final episodeDetails = {
            'id': episodeId,
            'number': parts.length >= 4 ? int.tryParse(parts[3]) ?? 1 : 1,
            'url': '', // Not needed for sandbox testing
            'title': null,
          };
          
          args['episode'] = episodeDetails;
          args['server'] = serverName.isNotEmpty ? serverName : 'vidking'; // Use provided server name or default
        } else {
          args['episodeId'] = episodeId; // Fallback to old format
        }
      }

      // Execute sandbox test with installed extension
      final result = await manager.executeSandboxTest(
        extensionId: _selectedExtensionId!,
        method: _selectedMethod,
        args: args,
      );

      if (!mounted) return;

      setState(() {
        _consoleLogs = result.consoleLogs;
        
        if (result.success) {
          // Format output for display
          if (result.output != null) {
            try {
              // Try to format as JSON if possible
              final jsonStr = const JsonEncoder.withIndent('  ').convert(result.output);
              _output = jsonStr;
            } catch (e) {
              // If not JSON, just convert to string
              _output = result.output.toString();
            }
          } else {
            _output = 'No output returned';
          }
          
          // Show success message
          _showSuccessSnackBar('Execution completed successfully');
        } else {
          // Format error message with more context
          final errorMsg = result.errorMessage ?? 'Unknown error occurred';
          _output = _formatErrorMessage(errorMsg);
          
          // Show error snackbar
          _showErrorSnackBar('Execution failed: $errorMsg');
        }
      });

      // Auto-scroll to bottom of logs
      if (_consoleLogs.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_logsScrollController.hasClients) {
            _logsScrollController.animateTo(
              _logsScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() {
        _output = 'ERROR: ${e.message}';
      });
      _showErrorSnackBar('Extension not found or has been removed');
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() {
        _output = 'ERROR: Unexpected error occurred\n\n$e\n\nStack trace:\n$stackTrace';
      });
      _showErrorSnackBar('Unexpected error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isExecuting = false;
        });
        // Reset animation
        _animationController.reset();
      }
    }
  }

  String _formatErrorMessage(String errorMsg) {
    // Add helpful context to common error messages
    if (errorMsg.contains('timeout') || errorMsg.contains('timed out')) {
      return 'ERROR: Execution Timeout\n\n'
          'The extension took longer than 30 seconds to execute.\n\n'
          'Possible causes:\n'
          '• The extension is making slow network requests\n'
          '• The extension has an infinite loop\n'
          '• The media source is not responding\n\n'
          'Original error: $errorMsg';
    } else if (errorMsg.contains('not found')) {
      return 'ERROR: Not Found\n\n'
          'The requested resource could not be found.\n\n'
          'Possible causes:\n'
          '• Invalid media title or show ID\n'
          '• Extension does not support this method\n'
          '• Media source is unavailable\n\n'
          'Original error: $errorMsg';
    } else if (errorMsg.contains('network') || errorMsg.contains('connection')) {
      return 'ERROR: Network Error\n\n'
          'Failed to connect to the media source.\n\n'
          'Possible causes:\n'
          '• No internet connection\n'
          '• Media source is down\n'
          '• Network timeout\n\n'
          'Original error: $errorMsg';
    } else if (errorMsg.contains('disabled')) {
      return 'ERROR: Extension Disabled\n\n'
          'The selected extension is currently disabled.\n\n'
          'Please enable the extension from the Extensions screen and try again.\n\n'
          'Original error: $errorMsg';
    } else {
      return 'ERROR: $errorMsg';
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _copyOutput() {
    if (_output.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _output));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text(
                'Output copied to clipboard',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _clearOutput() {
    setState(() {
      _output = '';
    });
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              'Output cleared',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _copyConsoleLogs() {
    if (_consoleLogs.isNotEmpty) {
      final logsText = _consoleLogs
          .map((log) => '${log.formattedTimestamp} ${log.levelPrefix} ${log.message}')
          .join('\n');
      
      Clipboard.setData(ClipboardData(text: logsText));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text(
                'Console logs copied to clipboard',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _clearLogs() {
    setState(() {
      _consoleLogs = [];
    });
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              'Logs cleared',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  /// Parse a date string into a FuzzyDate object
  FuzzyDate? _parseFuzzyDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    
    try {
      final date = DateTime.parse(dateString);
      return FuzzyDate(
        year: date.year,
        month: date.month,
        day: date.day,
      );
    } catch (e) {
      debugPrint('Failed to parse date: $dateString');
      return null;
    }
  }
}
