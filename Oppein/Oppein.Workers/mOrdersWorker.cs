using System;
using System.Windows.Forms;
using inResponse.Support;
using inResponse.Workers;

namespace Tech2020.InSight.Oppein.Workers
{
    public class mOrdersWorker:Worker
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
            if (helper.IsInteractive)//手工调用
            {
                try
                {
                    using (var form = new Forms.mOrdersForm(helper.Connection, Convert.ToInt32(algId)))
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
            //return 0;
            return result;
        }
    }
}
