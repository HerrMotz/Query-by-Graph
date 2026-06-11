import axios from "axios";

export type WikiDataEntity = {
  id: string;
  title: string;
  pageid: number;
  datatype: string;
  concepturi: string;
  repository: string;
  url: string;
  display: {
    label: {
      value: string;
      language: string;
    };
    description: {
      value: string;
      language: string;
    };
  };
  label: string;
  description: string;
  match: {
    type: string;
    language: string;
    text: string;
  };
  aliases?: string[];
};

export type WikiDataApiResponse = {
  errors: string[],
  searchinfo: object,
  search: WikiDataEntity[],
  success: number,
}

function queryWikidata({
                         action = 'wbsearchentities',
                         search = '',
                         language = 'en',
                         uselang = 'en',
                         type = '',
                         format = 'json',
                         formatversion = 2,
                         errorformat = 'plaintext',
                         origin = '*',
                         limit = 12
                       } = {}): Promise<WikiDataApiResponse> {
  const url = 'https://www.wikidata.org/w/api.php';

  if (!search) {
    return Promise.resolve({ search: [], errors: [], success: 0, searchinfo: {} });
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
    limit
  };

  return axios.get(url, { params })
    .then(response => {
      return response.data;
    })
    .catch(error => {
      alert('Error while querying the WikiData API: ' + error);
      console.error('Error:', error);
    });
}

export {queryWikidata};
