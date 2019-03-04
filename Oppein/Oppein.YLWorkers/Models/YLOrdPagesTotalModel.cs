using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Tech2020.InSight.Oppein.YLWorkers.Models
{
    public class YLOrdPagesTotalModel
    {
        public string PageName { get; set; }
        public string PlateCategory { get; set; }
        public decimal TotalPrice { get; set; }

        /// <summary>
        /// Equals
        /// </summary>
        public override bool Equals(object obj)
        {
            YLOrdPagesTotalModel other = obj as YLOrdPagesTotalModel;
            return this.PageName == other.PageName && this.PlateCategory == other.PlateCategory;
        }
        /// <summary>
        /// GetHashCode
        /// </summary>
        public override int GetHashCode()
        {
            return (this.PlateCategory.GetHashCode() * 397) ^ this.PageName.GetHashCode();
        }
    }
}
