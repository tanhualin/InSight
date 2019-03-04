using System;
using System.Data.SqlClient;
using System.Windows.Forms;
using inResponse.Support;
using inResponse.Workers;
using NUnit.Framework;

namespace Tech2020.InSight.Oppein.YLWorkers
{
    public class YLOrdersWorker : Worker
    {
        public override short processTask(
            string task, string server, string database, out string returnMsg, out string returnParams)
        {
            var helper = new Helper(task, server, database, GetType().FullName);
            var result = (short)UnitTasks.RUN_SUCESS;
            returnMsg = "操作成功！";
            returnParams = "";
            var algId = helper.getTaskAttribute("algID");
            if (string.IsNullOrEmpty(algId))
            {
                throw new InvalidOperationException("algID 为空！");
            }
            //if (helper.IsInteractive)//手工调用
            //{
            //    var form = new Forms.YLOrderForm(helper.Connection,Convert.ToInt32(algId));
            //    //Run(form);
            //    new Thread(() => Application.Run(form)).Start();
            //}
            if (helper.IsInteractive)//手工调用
            {
                try
                {
                    using (var form = new Forms.YLOrderForm(helper.Connection, Convert.ToInt32(algId)))
                    {
                        form.WindowState = FormWindowState.Maximized;
                        form.ShowDialog();
                    }
                }
                catch (Exception err)
                {
                    returnMsg = "手工修改单操作失败！" + err.Message;
                    throw new InvalidOperationException("手工修改单操作失败！" + err.Message);
                }
            }
            return result;
        }
    }

    [TestFixture]
    public class YLOrdersTest
    {
        [Test]
        public void Test()
        {
            string SqlString = "Data Source=172.21.26.125;Initial Catalog=InSight;User ID=sa;Password=2020;Connect Timeout=15;";
            using (SqlConnection sql=new SqlConnection(SqlString))
            {
                sql.Open();
                var form = new Forms.YLOrderForm(sql, 37576760);    //37575729,37576737，37576738,37576743
                form.ShowDialog();
                //Run(form);
                //new Thread(() => Application.Run(form)).Start();
            }
        }
    }
}
