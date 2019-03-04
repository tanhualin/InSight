using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Linq;
using System.Net.NetworkInformation;
using System.Text;
using System.Threading.Tasks;

namespace Tech2020.InSight.Oppein.Workers.Common
{
    public class CommonHelper
    {
        /// <summary>
        /// 将table数据转换成实体
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="table"></param>
        /// <returns></returns>
        public static T GetEntity<T>(DataTable table) where T : new()
        {
            T entity = new T();
            foreach (DataRow row in table.Rows)
            {
                foreach (var item in entity.GetType().GetProperties())
                {
                    if (row.Table.Columns.Contains(item.Name))
                    {
                        if (row.Table.Columns.Contains(item.Name))
                        {
                            if (DBNull.Value != row[item.Name] && row[item.Name].ToString() != "NULL")
                            {
                                if (item.PropertyType.IsGenericType && item.PropertyType.GetGenericTypeDefinition().Equals(typeof(Nullable<>)))//判断convertsionType是否为nullable泛型类  
                                {
                                    //如果type为nullable类，声明一个NullableConverter类，该类提供从Nullable类到基础基元类型的转换  
                                    System.ComponentModel.NullableConverter nullableConverter = new System.ComponentModel.NullableConverter(item.PropertyType);
                                    //将type转换为nullable对的基础基元类型  
                                    item.SetValue(entity, Convert.ChangeType(row[item.Name], nullableConverter.UnderlyingType), null);
                                }
                                else
                                {
                                    item.SetValue(entity, Convert.ChangeType(row[item.Name], item.PropertyType), null);
                                }
                            }
                        }
                    }
                }
            }

            return entity;
        }

        /// <summary>
        /// 将Table数据转换成实体列表
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="table"></param>
        /// <returns></returns>
        public static IList<T> GetEntities<T>(DataTable table) where T : new()
        {
            IList<T> entities = new List<T>();
            foreach (DataRow row in table.Rows)
            {
                T entity = new T();
                foreach (var item in entity.GetType().GetProperties())
                {
                    if (row.Table.Columns.Contains(item.Name))
                    {
                        if (DBNull.Value != row[item.Name] && row[item.Name].ToString() != "NULL")
                        {
                            if (item.PropertyType.IsGenericType && item.PropertyType.GetGenericTypeDefinition().Equals(typeof(Nullable<>)))//判断convertsionType是否为nullable泛型类  
                            {
                                //如果type为nullable类，声明一个NullableConverter类，该类提供从Nullable类到基础基元类型的转换  
                                System.ComponentModel.NullableConverter nullableConverter = new System.ComponentModel.NullableConverter(item.PropertyType);
                                //将type转换为nullable对的基础基元类型  
                                item.SetValue(entity, Convert.ChangeType(row[item.Name], nullableConverter.UnderlyingType), null);
                            }
                            else
                            {
                                item.SetValue(entity, Convert.ChangeType(row[item.Name], item.PropertyType), null);
                            }
                        }
                    }
                }
                entities.Add(entity);
            }
            return entities;
        }
        /// <summary>
        /// 将实体转换成table
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="list"></param>
        /// <returns></returns>
        public static DataTable ConvertToTable<T>(IList<T> list)
        {
            Type entityType = typeof(T);
            DataTable table = new DataTable(entityType.Name);
            PropertyDescriptorCollection properties = TypeDescriptor.GetProperties(entityType);
            foreach (PropertyDescriptor prop in properties)
            {
                if (prop.PropertyType.IsGenericType &&
                    prop.PropertyType.GetGenericTypeDefinition().Equals(typeof(Nullable<>)))
                {
                    //如果type为nullable类，声明一个NullableConverter类，该类提供从Nullable类到基础基元类型的转换  
                    System.ComponentModel.NullableConverter nullableConverter =
                        new System.ComponentModel.NullableConverter(prop.PropertyType);
                    table.Columns.Add(prop.Name, nullableConverter.UnderlyingType);

                }
                else
                {
                    table.Columns.Add(prop.Name, prop.PropertyType);
                }
            }
            foreach (T item in list)
            {
                DataRow row = table.NewRow();
                foreach (PropertyDescriptor prop in properties)
                    if (prop.GetValue(item) != null)
                    {
                        row[prop.Name] = prop.GetValue(item);
                    }
                table.Rows.Add(row);
            }
            return table;
        }
    }
}
