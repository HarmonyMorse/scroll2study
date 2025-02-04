import { describe, it, expect } from 'vitest'
import request from 'supertest'
import app from './index'

describe('Backend Tests', () => {
    it('should respond with a welcome message on /', async () => {
        const res = await request(app).get('/')
        expect(res.status).toBe(200)
        expect(res.body.message).toBe('Backend is running!')
    })
}) 