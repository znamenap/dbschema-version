using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace DbSchema.Version.Contributors.Model
{
    /// <summary>
    /// Represents the model of linked static data files in a single file used for deployment.
    /// </summary>
    public class StaticDataModel
    {
        private const string RootElementName = "StaticDataModel";
        private readonly XElement items;

        private StaticDataModel(XElement items)
        {
            this.items = items;
        }

        public void Add(string fileName, Stream content)
        {
            using (var reader = new StreamReader(content))
            {
                var fileContent = reader.ReadToEnd();
                var staticDataModelItem = new XElement("StaticData",
                    new XAttribute("fileName", fileName),
                    new XCData(fileContent));

                items.Add(staticDataModelItem);
            }
        }

        public void Save(Stream stream)
        {
            var document = new XDocument(new XElement(RootElementName, items));
            document.Save(stream);
        }

        public static bool IsStaticDataDeploymentUnit(string filename)
        {
            return filename.EndsWith(".data.sql", StringComparison.OrdinalIgnoreCase);
        }

        public static StaticDataModel Create()
        {
            return new StaticDataModel(new XElement("Items"));
        }

        public static StaticDataModel Load(Stream stream)
        {
            var document = XDocument.Load(stream);
            if (document.Root?.Name.LocalName != RootElementName)
            {
                throw new InvalidOperationException(
                    $"Unexpected root element {document.Root?.Name} where expecting {RootElementName}");
            }

            var items = document.Root.Element("Items");
            return new StaticDataModel(items);
        }

        public IEnumerable<Tuple<string,string>> GetItems()
        {
            return items.Elements().Select(e =>
            {
                var fileName = e.Attribute("fileName")?.Value;
                var value = e.Value;
                return new Tuple<string, string>(fileName, value);
            });
        }
    }
}
