import {AsyncLocalStorage} from 'node:async_hooks';
import type {ChatGPTUser} from '../../app/chatgpt-auth';
import {getDatabase} from './database';
export const requestContext=new AsyncLocalStorage<{user:ChatGPTUser|null}>();
export async function getChatGPTUser(){return requestContext.getStore()?.user??null}
export const env={get DB(){return getDatabase()},get ADMIN_EMAIL(){return process.env.ADMIN_EMAIL}};
