using System;
using System.Data;
using System.Data.SqlClient;
using System.Windows;

namespace RepairRequestsApp
{
    public partial class StatisticsWindow : Window
    {
        private string connectionString;

        public StatisticsWindow(string connectionString)
        {
            InitializeComponent();
            this.connectionString = connectionString;
            LoadStatistics();
        }

        private void LoadStatistics()
        {
            try
            {
                string query1 = "SELECT COUNT(*) FROM RepairRequests WHERE Status = 'Выполнено'";
                using (SqlConnection connection = new SqlConnection(connectionString))
                using (SqlCommand command = new SqlCommand(query1, connection))
                {
                    connection.Open();
                    int completedCount = Convert.ToInt32(command.ExecuteScalar());
                    TxtCompletedCount.Text = completedCount.ToString();
                }

                string query2 = @"
                    SELECT ISNULL(AVG(DATEDIFF(HOUR, RequestDate, ActualCompletionDate)), 0) 
                    FROM RepairRequests 
                    WHERE Status = 'Выполнено' AND ActualCompletionDate IS NOT NULL";

                using (SqlConnection connection = new SqlConnection(connectionString))
                using (SqlCommand command = new SqlCommand(query2, connection))
                {
                    connection.Open();
                    int averageHours = Convert.ToInt32(command.ExecuteScalar());
                    TxtAverageTime.Text = $"{averageHours} часов";
                }

                string query3 = @"
                    SELECT ft.TypeName, COUNT(r.RequestID) AS Count
                    FROM FaultTypes ft
                    LEFT JOIN RepairRequests r ON ft.FaultTypeID = r.FaultTypeID
                    GROUP BY ft.TypeName
                    ORDER BY COUNT(r.RequestID) DESC";

                using (SqlConnection connection = new SqlConnection(connectionString))
                using (SqlCommand command = new SqlCommand(query3, connection))
                using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                {
                    DataTable dataTable = new DataTable();
                    adapter.Fill(dataTable);
                    DataGridFaultStats.ItemsSource = dataTable.DefaultView;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка загрузки статистики: {ex.Message}", "Ошибка");
            }
        }

        private void BtnRefresh_Click(object sender, RoutedEventArgs e)
        {
            LoadStatistics();
        }
    }
}