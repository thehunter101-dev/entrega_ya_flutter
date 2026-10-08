import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import 'public/public_tracking_view.dart';
import 'admin/admin_dashboard.dart';
import 'dispatcher/dispatcher_dashboard.dart';
import 'driver/driver_dashboard.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Company? _selectedCompany;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToDashboard(BuildContext context, AppUser user) {
    // Perform login in provider
    final state = Provider.of<AppState>(context, listen: false);
    state.login(user);

    // Direct user to appropriate screen
    Widget destination;
    switch (user.role) {
      case UserRole.admin:
        destination = const AdminDashboard();
        break;
      case UserRole.dispatcher:
        destination = const DispatcherDashboard();
        break;
      case UserRole.driver:
        destination = const DriverDashboard();
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final db = state.db;

    if (_selectedCompany == null && db.companies.isNotEmpty) {
      _selectedCompany = state.currentCompany ?? db.companies.first;
    }

    // Filter users by selected company
    final companyUsers = db.users.where((u) => u.empresaId == _selectedCompany?.id).toList();
    final admins = companyUsers.where((u) => u.role == UserRole.admin).toList();
    final dispatchers = companyUsers.where((u) => u.role == UserRole.dispatcher).toList();
    final drivers = companyUsers.where((u) => u.role == UserRole.driver).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.local_shipping, color: Colors.blue[900], size: 30),
            const SizedBox(width: 8),
            const Text(
              'EntregaYa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 0.5),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue[900],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue[900],
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.badge), text: 'Acceso Personal Demo'),
            Tab(icon: Icon(Icons.search), text: 'Rastreo de Paquetes'),
          ],
        ),
        actions: [
          // Reset data button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: OutlinedButton.icon(
              onPressed: () {
                state.resetDemoData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Base de datos demo restablecida con éxito.'),
                      ],
                    ),
                    backgroundColor: Colors.blue[900],
                  ),
                );
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Restablecer Demo', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[900],
                side: BorderSide(color: Colors.blue[900]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. QUICK LOGIN TAB
          SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome & Company Selector Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bienvenido al Entorno de Pruebas',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Seleccione la empresa para aislar los datos (Multi-tenant) y pulse cualquier usuario para ingresar sin contraseña.',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            
                            // Tenant selector
                            const Text(
                              'Empresa Activa (Tenant):',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: db.companies.map((company) {
                                final isSelected = _selectedCompany?.id == company.id;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: ChoiceChip(
                                      label: Container(
                                        alignment: Alignment.center,
                                        width: double.infinity,
                                        child: Text(
                                          company.name,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.blue[900],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: Colors.blue[900],
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: Colors.blue[900]!),
                                      ),
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _selectedCompany = company;
                                          });
                                          state.selectCompany(company);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Direct Quick-Login Action Buttons Card
                    Card(
                      elevation: 2,
                      color: Colors.blue[900],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.flash_on, color: Colors.amber, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Ingreso Rápido de Demo (1 Clic)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Acceda instantáneamente con el rol seleccionado para la prueba de 5 minutos:',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: admins.isEmpty ? null : () => _navigateToDashboard(context, admins.first),
                                  icon: const Icon(Icons.admin_panel_settings, size: 18),
                                  label: const Text('Entrar como Admin'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber[700],
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: dispatchers.isEmpty ? null : () => _navigateToDashboard(context, dispatchers.first),
                                  icon: const Icon(Icons.corporate_fare, size: 18),
                                  label: const Text('Entrar como Operativo'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.blue[900],
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: drivers.isEmpty ? null : () => _navigateToDashboard(context, drivers.first),
                                  icon: const Icon(Icons.local_shipping, size: 18),
                                  label: const Text('Entrar como Chofer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ROLES LOGIN CARDS
                    _buildRoleSection(
                      context: context,
                      title: 'Administrador (Control Total)',
                      icon: Icons.admin_panel_settings,
                      iconColor: Colors.deepPurple,
                      description: 'Acceso a comisiones, conductores, vehículos, reportes ejecutivos y auditoría.',
                      usersList: admins,
                    ),
                    const SizedBox(height: 16),

                    _buildRoleSection(
                      context: context,
                      title: 'Despachadores / Operativos',
                      icon: Icons.corporate_fare,
                      iconColor: Colors.blue[800]!,
                      description: 'Registrar nuevos paquetes, generar links, agrupar rutas y aprobar liquidaciones.',
                      usersList: dispatchers,
                    ),
                    const SizedBox(height: 16),

                    _buildRoleSection(
                      context: context,
                      title: 'Choferes / Repartidores (Móvil)',
                      icon: Icons.local_shipping,
                      iconColor: Colors.green[800]!,
                      description: 'Visualizar ruta de entregas asignada, capturar firma digital táctil y registrar fallos.',
                      usersList: drivers,
                      isDriverGrid: true,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),

          // 2. PUBLIC TRACKING TAB
          const PublicTrackingView(),
        ],
      ),
    );
  }

  Widget _buildRoleSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required String description,
    required List<AppUser> usersList,
    bool isDriverGrid = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),

            if (isDriverGrid)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  mainAxisExtent: 75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: usersList.length,
                itemBuilder: (context, index) {
                  final user = usersList[index];
                  return _buildUserTile(context, user, isDriver: true);
                },
              )
            else
              Column(
                children: usersList.map((user) => _buildUserTile(context, user)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, AppUser user, {bool isDriver = false}) {
    return Card(
      color: Colors.grey[50],
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: () => _navigateToDashboard(context, user),
        hoverColor: Colors.blue[50],
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(
            user.role == UserRole.admin
                ? Icons.lock_person
                : user.role == UserRole.dispatcher
                    ? Icons.assignment_ind
                    : Icons.directions_car,
            color: Colors.blue[900],
            size: 20,
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
        subtitle: isDriver
            ? Text(
                'Vehículo: ${user.vehicleModel} (${user.licensePlate})',
                style: const TextStyle(fontSize: 11),
              )
            : Text(
                'Usuario: ${user.username}',
                style: const TextStyle(fontSize: 11),
              ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
      ),
    );
  }
}
