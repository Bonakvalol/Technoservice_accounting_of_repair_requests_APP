using System;
using System.Windows;

namespace RepairRequestsApp
{
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            AppDomain.CurrentDomain.UnhandledException += (sender, args) =>
            {
                MessageBox.Show($"Критическая ошибка: {args.ExceptionObject}",
                    "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            };
        }
    }
}