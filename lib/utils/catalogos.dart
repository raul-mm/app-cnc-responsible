// Catálogos fijos usados por las pantallas y la base de datos.

const List<String> cargosEquipo = [
  'Responsable',
  'Viceresponsable',
  'Corresponsable',
];

const List<String> rolesCatequista = ['Responsable', 'Catequista'];

const List<String> tiposGrupo = [
  'Palabra',
  'Eucaristía',
  'Artículo',
  'Doméstica',
];

const List<String> tiposCarisma = [
  'Presbítero',
  'Seminarista',
  'Diácono',
  'Ostiario',
  'Lector',
  'Familia en misión',
  'Itinerante',
];

/// Carismas que ya no se asignan a mano: los catequistas y salmistas salen
/// de sus propias tablas y el resto se retiró del catálogo.
const List<String> carismasRetirados = [
  'Catequista',
  'Salmista / Cantor',
  'Acólito',
  'Responsable de Salmos',
  'Vocación religiosa',
];

const List<String> pasosCamino = [
  'Precatecumenado',
  'Primer escrutinio',
  'Shemá',
  'Segundo escrutinio',
  'Iniciación a la oración',
  'Traditio Symboli',
  'Redditio Symboli',
  'Padre Nuestro',
  'Elección',
  'Renovación de promesas bautismales',
];

const List<String> estadosCiviles = ['Soltero', 'Casado', 'Viudo', 'Divorciado'];
