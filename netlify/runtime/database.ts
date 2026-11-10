import pg from 'pg';
pg.types.setTypeParser(20, Number);
pg.types.setTypeParser(1700, Number);

// This adapter retains the existing parameterized D1 route contracts on Postgres.
export function postgresSQL(source: string) {
  let sql = source.replace(/INSERT OR IGNORE INTO/i, 'INSERT INTO');
  if (/INSERT OR IGNORE INTO/i.test(source)) sql += ' ON CONFLICT DO NOTHING';
  sql = sql.replace(/\(julianday\(completed_at\)-julianday\(called_at\)\)\*1440/g,
    '(EXTRACT(EPOCH FROM (completed_at::timestamptz-called_at::timestamptz))/60)');
  const table = sql.match(/^INSERT INTO (usage_totals|department_usage)/i)?.[1];
  if (table) sql = sql.replace(/SET (.*)$/i, (_, tail) => 'SET ' + tail.replace(/=(count|duration_total|fallback_count|measured_count)\+/g, `=${table}.$1+`));
  // Pooler connections can change between transactions: never depend on session search_path.
  const tables='appointments|bookings|departments|doctors|feedback|holidays|hospitals|doctor_schedules|appointment_slots|usage_totals|department_usage|facility_directory|followup_reminders|staff_requests|doctor_presence|hospital_resources|operations_audit|queue_tokens|staff_roles';
  sql=sql.replace(new RegExp(`\\b(FROM|JOIN|INTO|UPDATE)\\s+(${tables})\\b`,'gi'),'$1 care.$2');
  let n=0;
  return sql.replace(/'(?:''|[^'])*'|"(?:""|[^"])*"|`([^`]+)`|\?|\bend\b/g, (token, identifier) => {
    if (token === '?') return `$${++n}`;
    if (identifier) return `"${identifier}"`;
    if (token === 'end') return '"end"';
    return token;
  });
}
export type QueryConnection = {query: (sql:string, values?:unknown[])=>Promise<{rows:Record<string,unknown>[];rowCount?:number|null;affectedRows?:number}>};
function convertedError(e:unknown):never {
  const error=e as {code?:string;constraint?:string};
  if(error.code==='23505') throw new Error(error.constraint==='one_active_booking_per_slot'?'UNIQUE constraint failed: bookings.slot_id':'UNIQUE constraint failed');
  throw e;
}
export class Statement {
  constructor(readonly db:Database,readonly sql:string,readonly values:unknown[]=[]){}
  bind(...values:unknown[]){return new Statement(this.db,this.sql,values)}
  async execute(connection:QueryConnection){try{const r=await connection.query(postgresSQL(this.sql),this.values);return {results:r.rows,success:true,meta:{changes:r.rowCount??r.affectedRows??0}}}catch(e){return convertedError(e)}}
  all(){return this.execute(this.db.connection)}
  run(){return this.all()}
  async first(column?:string){const r=(await this.all()).results[0]??null;return column&&r?r[column]:r}
}
export class Database {
  constructor(readonly connection:QueryConnection,readonly transaction?:<T>(fn:(c:QueryConnection)=>Promise<T>)=>Promise<T>){}
  prepare(sql:string){return new Statement(this,sql)}
  async batch(statements:Statement[]){
    const run=async(c:QueryConnection)=>{const results=[];for(const s of statements)results.push(await s.execute(c));return results};
    if(!this.transaction)throw new Error('Transactional connection required');
    return this.transaction(run);
  }
}
let database:Database|undefined;
export function getDatabase(){
 if(database)return database;
 if(!process.env.DATABASE_URL)throw new Error('DATABASE_URL is not configured');
 const pool=new pg.Pool({connectionString:process.env.DATABASE_URL,password:process.env.PGPASSWORD,max:2,idleTimeoutMillis:10000,connectionTimeoutMillis:10000});
 database=new Database(pool,async fn=>{const c=await pool.connect();try{await c.query('BEGIN');const r=await fn(c);await c.query('COMMIT');return r}catch(e){await c.query('ROLLBACK');throw e}finally{c.release()}});
 return database;
}
