import axios, {AxiosInstance} from "axios";
import {
  WikibaseDataSource,
  WikiDataEntityDetails,
  WikiDataResponse,
  WikiDataSearchApiResponse
} from "../types/WikibaseDataSource.ts";

class WikibaseDataService {
  private api: AxiosInstance;
  private readonly languages: string[];
  private dataSource: WikibaseDataSource;

  constructor(dataSource: WikibaseDataSource) {
    const baseURL = dataSource.uri;
    this.languages = dataSource.preferredLanguages;
    this.dataSource = dataSource;

    console.log(`Initializing WikiDataService with baseURL: ${baseURL}`);

    this.api = axios.create({
      baseURL,
      params: {
        origin: '*',
      },
    });
  }

  /**
   * Fetch metadata about a WikiData item by its ID.
   * @param itemId - The WikiData item ID (e.g., Q42 for Douglas Adams).
   * @returns Metadata object.
   */
  async getItemMetaInfo(
    itemId: string,
  ): Promise<WikiDataEntityDetails | null> {

    const languages = this.languages;

    // check if it is a variable
    if (itemId.startsWith('?')) {
      return null;
    }

    try {
      const response = await this.api.get<WikiDataResponse>('', {
        params: {
          action: 'wbgetentities',
          ids: itemId,
          format: 'json',
          props: 'labels|descriptions|claims',
          origin: '*', // Required for CORS
        },
      });

      console.log('Api response', response);

      const entity = response.data.entities[itemId];
      if (!entity) {
        throw new Error(`Item with ID ${itemId} not found`);
      }

      // TODO this can be done using the API.
      const filteredLabels = Object.fromEntries(
        Object.entries(entity.labels).filter(([lang]) => languages.includes(lang))
      );
      // TODO this as well. Just pass the "languages" parameter to the action API
      const filteredDescriptions = Object.fromEntries(
        Object.entries(entity.descriptions).filter(([lang]) => languages.includes(lang))
      );

      // Construction of images
      let imageUrl = null;

      if(entity.claims && entity.claims.P18){
        const imageClaim = entity.claims.P18[0];
        const imageValue = imageClaim.mainsnak.datavalue.value;

        imageUrl = this.getCommonsImageUrl(imageValue);
      }

      // Fetch the labels for all properties in the claims
      const propertyIds = Object.keys(entity.claims); // P-Numbers
      const propertyLabels = await this.getLabels(propertyIds, languages[0]); // Corresponding labels

      // Fetch the labels for all items in the claims
      const itemIds = new Set<string>();
      for(const claimsArray of Object.values(entity.claims)){ // Loop through all claims for each P-Number
        for(const claim of claimsArray){ // Loop through contents of each claim
          const mainsnak = claim.mainsnak;
          if(mainsnak.datatype === 'wikibase-item' && mainsnak.datavalue){ // if mainsnak is wikibase-item its value is a Q/P-Number
            const itemId = mainsnak.datavalue.value.id;
            itemIds.add(itemId);
          }
        }
      }

      // extract labels for all items (like done above for properties)
      const itemLabels = await this.getLabels(Array.from(itemIds), languages[0]);

      // Returns moidified claim object with labels instead of Q/P-Numbers
      const claimsWithLabels = Object.fromEntries(
        Object.entries(entity.claims).map(([property, claims]) => [
          propertyLabels[property] || property, // looks up the label for the property and replaces the P-Number with it
          claims.map(claim => {
            const mainsnak = claim.mainsnak;
            if (mainsnak.datatype === 'wikibase-item' && mainsnak.datavalue) {
              const itemId = mainsnak.datavalue.value.id;
               // looks up the label for the item and replaces the Q-Number with it
              mainsnak.datavalue.value = itemLabels[itemId] || itemId;
            }
            else if (mainsnak.datatype === 'time' && mainsnak.datavalue){
              mainsnak.datavalue.value = this.formatWikidataDate(mainsnak.datavalue.value);
            }
            return claim;
          }),
        ])
      );

      return {
        ...entity,
        labels: filteredLabels,
        descriptions: filteredDescriptions,
        claims: claimsWithLabels,
        image: imageUrl,
      };
    } catch (error) {
      console.error(`Failed to fetch data for item ${itemId}:`, error);
      return null;
    }
  }

  // Format images correctly
  private getCommonsImageUrl(filename: string): string {
    const commonsUrl = 'https://commons.wikimedia.org/wiki/Special:FilePath/';
    const encodedFilename = encodeURIComponent(filename);
    return `${commonsUrl}${encodedFilename}`;
  }

  //Format dates correctly
  private formatWikidataDate(dateValue: { time: string; precision: number }): string {
    // ExampleDate: { time: "+1965-01-01T00:00:00Z", timezone: 0, ... }
    const time = dateValue.time;
    const precision = dateValue.precision;

    let dateStr = time.startsWith('+') ? time.substring(1) : time;

    // Extract date components for toLocaleStringDate method
    const year = dateStr.substring(0, 4);
    const month = dateStr.substring(5, 7);
    const day = dateStr.substring(8, 10);

    let formattedDate;
    const options: Intl.DateTimeFormatOptions = {};

    const language = this.dataSource.preferredLanguages || 'en';

    if (precision === 9) {
      formattedDate = year;
    }
    else if (precision === 10) {
      options.year = 'numeric';
      options.month = 'long';
      const date = new Date(`${year}-${month}-01`);
      formattedDate = date.toLocaleDateString(language, options);
    }
    else if (precision >= 11) {
      options.year = 'numeric';
      options.month = 'long';
      options.day = 'numeric';
      const date = new Date(`${year}-${month}-${day}`);
      formattedDate = date.toLocaleDateString(language, options);
    }
    else {
      formattedDate = year;
    }

    return formattedDate;
  }

  /**
   * Query WikiData API for search results.
   * @param search - The search query string.
   * @param language - The language to use for the search.
   * @param limit - The number of results to return.
   * @returns A promise resolving to the search results.
   */
  async queryWikidata({
                        search = '',
                        language = 'en',
                        limit = 12,
                        action = 'wbsearchentities',
                        uselang = 'en',
                        type = '',
                        format = 'json',
                        formatversion = 2,
                        errorformat = 'plaintext',
                        origin = '*',
                      }: {
    search: string;
    language?: string;
    limit?: number;
    action?: string;
    uselang?: string;
    type?: string;
    format?: string;
    formatversion?: number;
    errorformat?: string;
    origin?: string;
  }): Promise<WikiDataSearchApiResponse> {
    if (!search) {
      return Promise.resolve({
        search: [],
        errors: [],
        success: 0,
        searchinfo: {},
      });
    }

    const params = {
      action,
      search,
      language,
      uselang,
      type,
      format,
      formatversion,
      errorformat,
      origin,
      limit,
    };

    try {
      const response = await this.api.get<WikiDataSearchApiResponse>('', { params });
      console.log("Api response for query: ", response.data);
      return response.data;
    } catch (error) {
      console.error('Error while querying the WikiData API:', error);
      return {
        search: [],
        errors: [],
        success: 0,
        searchinfo: {},
      };
    }
  }
  
  /**
   * Fetches the labels for a list of property IDs from the WikiData API.
   * 
   * @param propertyIds - An array of property IDs (e.g., ["P123", "P456"]).
   * @param language - The language code for the labels (default is 'en').
   * @returns A promise that resolves to an object mapping property IDs to their labels.
   * 
   * This function makes an API call to the WikiData API to fetch the labels for the given property IDs.
   * It returns an object where the keys are the property IDs and the values are the corresponding labels
   * in the specified language. If a label is not available in the specified language, the property ID itself
   * is used as the label.
   */
  async getLabels(
    propertyIds: string[], 
    language: string = 'en'
  ): Promise<{[key: string]: string}> {
    try {
      // For handling API limit
      const chunks = chunkArray(propertyIds, 50);
      const labels: { [key: string]: string } = {}; // Map of P/Q-Numbers to labels

      for (const chunk of chunks) {
        const response = await this.api.get<WikiDataResponse>('', {
          params: {
            action: 'wbgetentities',
            ids: chunk.join('|'),
            format: 'json',
            props: 'labels',
            languages: language,
            origin: '*',
          },
        });

        // DEBUG
        //console.log('API response', response.data);

        // Fill the labels object with the fetched data
        if (response.data.entities) {
          for (const [id, entity] of Object.entries(response.data.entities)) {
            if (entity && entity.labels && entity.labels[language]) {
              labels[id] = entity.labels[language].value;
            } else {
              labels[id] = id;
            }
            // console.log('converting property id to label:', id, labels[id]);
          }
        } else {
          console.error('No entities found in response:', response.data);
        }
      }
  
      return labels;
    } catch (error) {
      console.error('Failed to fetch property labels:', error);
      return {};
    }
  }
}

// Only 50 entities can be fetched at a time, so we need to split the array appart
function chunkArray<T>(array: T[], chunkSize: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < array.length; i += chunkSize) {
    chunks.push(array.slice(i, i + chunkSize));
  }
  return chunks;
}

export default WikibaseDataService;

// Example API Response
/**
 * {
  "entities": {
    "Q42": {
      "type": "item",
      "id": "Q42",
      "labels": {
        "en": {
          "language": "en",
          "value": "Douglas Adams"
        },
        // Other languages...
      },
      "descriptions": {
        "en": {
          "language": "en",
          "value": "English writer and humorist"
        },
        // Other languages...
      },
      "claims": {
        "P31": [
          {
            "mainsnak": {
              "snaktype": "value",
              "property": "P31",
              "datatype": "wikibase-item",
              "datavalue": {
                "value": {
                  "entity-type": "item",
                  "numeric-id": 5,
                  "id": "Q5"
                },
                "type": "wikibase-entityid"
              }
            },
            "type": "statement",
            "id": "Q42$D3A1F9C7-4F78-4F8D-9C07-8F36FAD6F0C9",
            "rank": "normal"
          }
          // More statements...
        ],
        "P19": [
          {
            "mainsnak": {
              "snaktype": "value",
              "property": "P19",
              "datatype": "wikibase-item",
              "datavalue": {
                "value": {
                  "entity-type": "item",
                  "numeric-id": 1794,
                  "id": "Q1794"
                },
                "type": "wikibase-entityid"
              }
            },
            "type": "statement",
            "id": "Q42$A1B2C3D4-E5F6-7890-1234-56789ABCDEF0",
            "rank": "normal"
          }
          // More statements...
        ]
        // More properties...
      },
      // Other entity data...
    }
  },
  "success": 1
}
 */