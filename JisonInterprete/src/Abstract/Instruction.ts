import { Environment } from "../Symbol/Environment";

export abstract class Instruction {

    public line: number;
    public column: number;

    constructor(line: number, column: number) {
        this.line = line;
        this.column = column + 1;
    }

    public abstract execute(environment : Environment) : any;

}