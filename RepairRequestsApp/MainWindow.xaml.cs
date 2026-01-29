using System;
using System.Data.SqlClient;
using System.Windows;
using System.Windows.Media;

namespace RepairRequestsApp
{
    public partial class MainWindow : Window
    {
        private string connectionString = @"Data Source=DESKTOR\SQLEXPRESSS;Initial Catalog=RepairRequestsDB;Integrated Security=True";

        public MainWindow()
        {
            InitializeComponent();
            CheckDatabaseConnection();
        }

        private void CheckDatabaseConnection()
        {
            try
            {
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    UpdateConnectionStatus(true);
                }
            }
            catch
            {
                UpdateConnectionStatus(false);
            }
        }

        private void UpdateConnectionStatus(bool isConnected)
        {
            if (isConnected)
            {
                ConnectionStatus.Background = Brushes.LightGreen;
                TxtConnectionStatus.Text = "Подключено";
            }
            else
            {
                ConnectionStatus.Background = Brushes.LightCoral;
                TxtConnectionStatus.Text = "Не подключено";
            }
        }

        private void BtnRequests_Click(object sender, RoutedEventArgs e)
        {
            var window = new RequestsWindow(connectionString);
            window.Owner = this;
            window.Show();
        }

        private void BtnClients_Click(object sender, RoutedEventArgs e)
        {
            var window = new ClientsWindow(connectionString);
            window.Owner = this;
            window.Show();
        }

        private void BtnEquipment_Click(object sender, RoutedEventArgs e)
        {
            var window = new EquipmentWindow(connectionString);
            window.Owner = this;
            window.Show();
        }

        private void BtnEmployees_Click(object sender, RoutedEventArgs e)
        {
            var window = new EmployeesWindow(connectionString);
            window.Owner = this;
            window.Show();
        }

        private void BtnStatistics_Click(object sender, RoutedEventArgs e)
        {
            var window = new StatisticsWindow(connectionString);
            window.Owner = this;
            window.Show();
        }

        private void BtnParts_Click(object sender, RoutedEventArgs e)
        {
            var window = new PartsWindow(connectionString);
            window.Owner = this;
            window.Show();
        }

        private void BtnAddRequest_Click(object sender, RoutedEventArgs e)
        {
            var window = new CreateRequestWindow(connectionString);
            window.Owner = this;
            bool? result = window.ShowDialog();

            if (result == true)
            {
                MessageBox.Show("Заявка успешно создана!", "Успех",
                    MessageBoxButton.OK, MessageBoxImage.Information);
            }
        }

        private void BtnBack_Click(object sender, RoutedEventArgs e)
        {
            foreach (Window window in OwnedWindows)
            {
                if (window.IsActive)
                {
                    window.Close();
                    break;
                }
            }
        }

        private void BtnTestConnection_Click(object sender, RoutedEventArgs e)
        {
            CheckDatabaseConnection();
            if (ConnectionStatus.Background == Brushes.LightGreen)
            {
                MessageBox.Show("Подключение к базе данных успешно!", "Информация",
                    MessageBoxButton.OK, MessageBoxImage.Information);
            }
            else
            {
                MessageBox.Show("Не удалось подключиться к базе данных", "Ошибка",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
    }
}