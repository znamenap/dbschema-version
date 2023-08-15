using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;

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

        /// <summary>
        /// Adds the static data file name and its content into the static data model.
        /// </summary>
        /// <param name="fileName">The file name which identifies the content.</param>
        /// <param name="content">The content of the file name.</param>
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

        /// <summary>
        /// Saves the static data model into the stream as the XML formatted file.
        /// </summary>
        /// <param name="stream">THe stream where to save the static data model.</param>
        public void Save(Stream stream)
        {
            var document = new XDocument(new XElement(RootElementName, items));
            document.Save(stream);
        }

        /// <summary>
        /// Determines if the filename matches data static data requirement file name mask: *.data.sql
        /// </summary>
        /// <param name="filename">The file name to test the rule with.</param>
        /// <returns>True if the file name eds with the file name mask.</returns>
        public static bool IsStaticDataDeploymentUnit(string filename)
        {
            return filename.EndsWith(".data.sql", StringComparison.OrdinalIgnoreCase);
        }

        /// <summary>
        /// Makes a new clear instance of the static data model.
        /// </summary>
        /// <returns>The new empty instance ready for adding new static data.</returns>
        public static StaticDataModel Create()
        {
            return new StaticDataModel(new XElement("Items"));
        }

        /// <summary>
        /// Loads the static data model from the stream.
        /// </summary>
        /// <param name="stream">The stream to load the model from.</param>
        /// <returns>The new static data model loaded from the stream</returns>
        /// <exception cref="InvalidOperationException">If there was an unexpected content of the stream to load data from.</exception>
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

        /// <summary>
        /// Returns the static data model items in sequence as it was created or loaded.
        /// </summary>
        /// <returns>The sequence of tuple items where the first item is the file name and the second item is the static data content.</returns>
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
