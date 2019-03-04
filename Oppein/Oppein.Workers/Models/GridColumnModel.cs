using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Tech2020.InSight.Oppein.Workers.Models
{
    public class GridColumnModel
    {
        ///<summary>--grid字段名</summary>
        public string cmFieldName { get; set; }
        ///<summary>--grid字段描述</summary>
        public string cmFieldDesc { get; set; }
        ///<summary>--grid字段类型</summary>
        public string cmFieldType { get; set; }
        ///<summary>	--grid字段宽度</summary>
        public int cmFieldWidth { get; set; }
        ///<summary>--绑定原数据字段</summary>
        public string cmOriginalField { get; set; }
        ///<summary>	--grid字段是否可编辑</summary>
        public bool cmFieldEdit { get; set; }
        ///<summary>	--grid字段是否隐藏</summary>
        public bool cmFieldVisible { get; set; }
        ///<summary>--操作类型</summary>
        public string optType { get; set; }
        /// <summary>
        /// 操作绑定的存储（如下拉框的绑定）
        /// </summary>
        public string optStoredProcedure { get; set; }

        ///<summary>	--grid字段序号</summary>
        public int cmOrderSort { get; set; }
        ///<summary>--页签名</summary>
        public string pageName { get; set; }
        ///<summary>	--页签序号</summary>
        public int pageSort { get; set; }
        ///<summary>	--订单类型{get;set;}</summary>
        public string PageStoredProcedure { get; set; }
        ///<summary>是否显示页签颜色</summary>
        public bool showPageColor { get; set; }

        /// <summary>
        /// 列绑定字段
        /// </summary>
        public string cmBindField { get; set; }
    }

    public class GridPagesModel
    {
        ///<summary>--页签名</summary>
        public string pageName { get; set; }
        ///<summary>	--页签序号</summary>
        public int pageSort { get; set; }
        ///<summary>	--订单类型{get;set;}</summary>
        public string PageStoredProcedure { get; set; }
        ///<summary>是否显示页签颜色</summary>
        public bool showPageColor { get; set; }
    }
}
